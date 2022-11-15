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
    case @box.purpose
    when "LOD"
      @box.build_samples(@batches["lod"], concentrations: (1..8).map{|e| 10**e}, replicates: 3, media: media)
      @box.build_samples(@batches["lod"], concentrations: [0], replicates: 4, media: media)

    when "Variants"
      @batches.each_value do |batch|
        @box.build_samples(batch, concentrations: [1, 4, 8].map{|e| 10**e}, replicates: 3, media: media)
      end

    when "Challenge"
      @batches.each do |key, batch|
        if key == "virus"
          @box.build_samples(batch, concentrations: [1, 4, 8].map{|e| 10**e}, replicates: 18, media: media)
        else
          @box.build_samples(batch, concentrations: [1, 4, 8].map{|e| 10**e}, replicates: 3, media: media)
        end
      end

    when "Other"
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
    case @box.purpose
    when "LOD"
      @box.errors.add(:lod, "A batch is required") unless @batches["lod"] || @box.errors.include?(:lod)
    when "Variants"
      @box.errors.add(:base, "You must select at least two batches") unless unique_batch_count >= 2
    when "Challenge"
      if @batches["virus"]
        @box.errors.add(:base, "You must select at least one distractor batch") unless unique_batch_count >= 2
      else
        @box.errors.add(:virus, "A virus batch is required") unless @box.errors.include?(:virus)
        @box.errors.add(:base, "You must select at least one distractor batch") unless unique_batch_count >= 1
      end
    when "Other"
      if @samples.empty?
        @box.errors.add(:base, "You must select at least one sample")
      elsif @samples.any? { |_, sample| sample.is_quality_control? }
        @box.errors.add(:base, "You can't select a QC sample")
      end
    end
  end

  def unique_batch_count
    @batches.map { |_, b| b.try(&:uuid) }.uniq.size
  end
end
