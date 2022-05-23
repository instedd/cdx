class BoxForm
  attr_reader :box, :batch_uuids

  delegate :purpose, :purpose=, to: :box
  delegate_missing_to :box

  def self.build(navigation_context, params = nil)
    box = Box.new(
      institution: navigation_context.institution,
      site: navigation_context.site,
    )

    if params
      batch_uuids = params.delete(:batch_uuids) || {}
      box.attributes = params
    else
      batch_uuids = {}
    end

    new(box, batch_uuids)
  end

  def initialize(box, batch_uuids)
    @box = box
    @batch_uuids = batch_uuids
  end

  def batches=(relation)
    records = relation.to_a

    @batches = @batch_uuids.transform_values do |batch_uuid|
      records.find { |b| b.uuid == batch_uuid }
    end.compact
  end

  def build_samples
    case @box.purpose
    when "LOD"
      @box.build_samples(@batches["lod"], concentration_exponents: 1..8, replicates: 3)

    when "Variants"
      @batches.each_value do |batch|
        @box.build_samples(batch, concentration_exponents: [1, 4, 8], replicates: 3)
      end

    when "Challenge"
      @batches.each do |key, batch|
        if key == "virus"
          @box.build_samples(batch, concentration_exponents: [1, 4, 8], replicates: 18)
        else
          @box.build_samples(batch, concentration_exponents: [1, 4, 8], replicates: 3)
        end
      end
    end
  end

  def valid?
    @box.valid?
    validate_existence_of_batches
    validate_batches_for_purpose
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

  def validate_batches_for_purpose
    count = @batches.map { |_, b| b.try(&:uuid) }.uniq.size

    case @box.purpose
    when "LOD"
      @box.errors.add(:lod, "A batch is required") unless @batches["lod"] || @box.errors.include?(:lod)
    when "Variants"
      @box.errors.add(:base, "You must select at least two batches") unless count >= 2
    when "Challenge"
      if @batches["virus"]
        @box.errors.add(:base, "You must select at least one distractor batch") unless count >= 2
      else
        @box.errors.add(:virus, "A virus batch is required") unless @box.errors.include?(:virus)
        @box.errors.add(:base, "You must select at least one distractor batch") unless count >= 1
      end
    end
  end
end
