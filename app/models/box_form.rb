class BoxForm
  attr_reader :box, :batch_uuids, :sample_uuids
  attr_accessor :media

  delegate :purpose, :purpose=, to: :box
  delegate_missing_to :box

  def self.build(navigation_context, params = {})
    box = Box.new(
      institution: navigation_context.institution,
      site: navigation_context.site,
      purpose: params[:purpose],
      blinded: params[:blinded],
    )
    new(box, params)
  end

  def initialize(box, params)
    @box = box
    @option = params[:samples].presence
    @concentrations = params[:concentrations].presence
    @media = params[:media].presence
    @batch_uuids = params[:batch_uuids].presence.to_h
    @sample_uuids = params[:sample_uuids].presence.to_h
  end

  def batches=(relation)
    records = relation.to_a

    @batches = @batch_uuids.transform_values do |batch_uuid|
      records.find { |b| b.uuid == batch_uuid }
    end.compact
  end

  def samples=(relation)
    records = relation.to_a

    @samples = @sample_uuids.transform_values do |batch_uuid|
      records.find { |b| b.uuid == batch_uuid }
    end.compact
  end

  def build_samples
    case @option
    when "add_batch"
      @batches.each do |key, batch|
        @concentrations[key].each do |i, concentration|
          @box.build_samples(batch, concentrations: [concentration['concentration']], replicates: concentration['replicate'].to_i, media: media, distractor: concentration['distractor'] == "on", instruction: concentration['instruction'])
        end
      end
    when "add_samples"
      @box.samples = @samples.values
    end
  end

  def valid?
    @box.valid?
    validate_existence_of_batches
    validate_existence_of_samples
    validate_batches_or_samples_for_purpose
    @box.errors.empty?
  end

  def save
    if valid?
      @box.save(validate: false)
    else
      false
    end
  end

  private

  def validate_existence_of_batches
    @batch_uuids.each do |key, batch_uuid|
      unless batch_uuid.blank? || @batches[key]
        @box.errors.add(key, "Batch doesn't exist")
      end
    end
  end

  def validate_existence_of_samples
    @sample_uuids.each do |key, sample_uuid|
      unless sample_uuid.blank? || @samples[key]
        @box.errors.add(key, "Sample doesn't exist")
      end
    end
  end

  def validate_batches_or_samples_for_purpose
    case @option
    when "add_batch"
      case @box.purpose
      when "LOD"
        @box.errors.add(:lod, "A batch is required") unless unique_batch_count >= 1
      when "Variants"
        @box.errors.add(:base, "You must select at least two batches") unless unique_batch_count >= 2
      when "Challenge"
        @box.errors.add(:base, "You must select at least one distractor batch") unless have_distractor_batch
        @box.errors.add(:virus, "A virus batch is required") unless have_virus_batch
      when "Other"
        if @samples.empty?
          @box.errors.add(:base, "You must select at least one sample")
        elsif @samples.any? { |_, sample| sample.is_quality_control? }
          @box.errors.add(:base, "You can't select a QC sample")
        end
      end
    when "add_samples"
      if @samples.empty?
        @box.errors.add(:base, "You must select at least one sample")
      elsif @samples.any? { |_, sample| sample.is_quality_control? }
        @box.errors.add(:base, "You can't select a QC sample")
      end
    end
  end

  private

  def unique_batch_count
    @batches.map { |_, b| b.try(&:uuid) }.uniq.size
  end

  def have_distractor_batch
    @batches.each do |key, _|
      @concentrations[key].each do |_, concentration|
        if concentration['distractor'] == "on" then return true end
      end
    end
    return false
  end

  def have_virus_batch
    @batches.each do |key, _|
      @concentrations[key].each do |_, concentration|
        if concentration['distractor'] != "on" then return true end
      end
    end
    return false
  end

end
