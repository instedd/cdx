class BoxForm
  attr_reader :box, :batch_numbers

  delegate :purpose, :purpose=, to: :box
  delegate :model_name, :errors, to: :box

  def self.build(navigation_context, params = nil)
    box = Box.new(
      institution: navigation_context.institution,
      site: navigation_context.site,
    )

    if params
      batch_numbers = params.delete(:batch_numbers) || {}
      box.attributes = params
    else
      batch_numbers = {}
    end

    new(box, batch_numbers)
  end

  def initialize(box, batch_numbers)
    @box = box
    @batch_numbers = batch_numbers
  end

  def batches=(relation)
    records = relation.to_a

    @batches = @batch_numbers.transform_values do |batch_number|
      records.find { |b| b.batch_number == batch_number }
    end.compact
  end

  def build_samples
    case @box.purpose
    when "LOD"
      @box.build_samples(@batches["lod"], exponents: 1..8, replicas: 3)

    when "Variants"
      @batches.each_value do |batch|
        @box.build_samples(batch, exponents: [1, 4, 8], replicas: 3)
      end

    when "Challenge"
      @batches.each do |key, batch|
        if key == "virus"
          @box.build_samples(batch, exponents: [1, 4, 8], replicas: 18)
        else
          @box.build_samples(batch, exponents: [1, 4, 8], replicas: 3)
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
    @batch_numbers.each do |key, batch_number|
      unless batch_number.blank? || @batches[key]
        @box.errors.add(key, "Batch doesn't exist")
      end
    end
  end

  def validate_batches_for_purpose
    count = @batches.map { |_, b| b.try(&:batch_number) }.uniq.size

    case @box.purpose
    when "LOD"
      @box.errors.add(:lod, "A batch is required") unless @batches["lod"] || @box.errors.include?(:lod)
    when "Variants"
      @box.errors.add(:base, "You must select at least two batches") unless count >= 2
    when "Challenge"
      @box.errors.add(:virus, "A virus batch is required") unless @batches["virus"] || @box.errors.include?(:virus)
      @box.errors.add(:base, "You must select at least one distractor batch") unless count >= 2
    end
  end
end
