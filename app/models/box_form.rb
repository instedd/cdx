# TODO: extract BoxBatchesForm and BoxSamplesForm descendants to distinguish
#       selected paths: create new samples from batches OR use samples
class BoxForm
  attr_reader :box, :option, :batch_uuids, :sample_uuids
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
    @params = params
    @option = params[:option]
    @media = params[:media].presence
    @batches_data = params[:batches].presence.to_h
    @batch_uuids = @batches_data.transform_values { |v| v[:batch_uuid] }
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

  def batches_data
    return [] if @batch_uuids.empty?

    @batches_data.map do |key, data|
      data[:batch_number] = @batches[key].batch_number
      data[:concentrations] = data[:concentrations].to_h.values
      data
    end
  end

  def samples_data
    # NOTE: duplicates the samples/autocomplete template (but returns an
    # Array<Hash> instead of rendering to a JSON String)
    samples.map do |sample|
      {
        uuid: sample.uuid,
        batch_number: sample.batch_number,
        concentration: sample.concentration,
      }
    end
  end

  def build_samples
    case @option
    when "add_batches"
      @batches_data.each do |batch_key, b|
        next if b[:batch_uuid].blank?

        b[:concentrations].each do |_, c|
          next if c[:replicate].blank? && c[:concentration].blank?

          @box.build_samples(
            @batches[batch_key],
            concentrations: [c[:concentration]],
            replicates: c[:replicate].to_i,
            distractor: ActiveModel::Type::Boolean.new.cast(b[:distractor]),
            instruction: b[:instruction].presence,
            media: @media,
          )
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
    when "add_batches"
      case @box.purpose
      when "LOD", "Other"
        @box.errors.add(:base, "A batch is required") unless unique_batch_count >= 1
      when "Variants"
        @box.errors.add(:base, "You must select at least two batches") unless unique_batch_count >= 2
      when "Challenge"
        @box.errors.add(:base, "A virus batch is required") unless have_virus_batch?
        @box.errors.add(:base, "You must select at least one distractor batch") unless have_distractor_batch?
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

  def have_virus_batch?
    @batches_data.any? do |_, b|
      !ActiveModel::Type::Boolean.new.cast(b[:distractor])
    end
  end

  def have_distractor_batch?
    @batches_data.any? do |_, b|
      ActiveModel::Type::Boolean.new.cast(b[:distractor])
    end
  end
end
