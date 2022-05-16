class BoxForm
  attr_reader :box, :batch_numbers, :batch_errors

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
    @batch_errors = {}
  end

  def batches=(relation)
    @batches = {}
    records = relation.to_a

    @batch_numbers.each do |key, batch_number|
      if batch = records.find { |b| b.batch_number == batch_number }
        @batches[key] = batch
      elsif batch_number.present?
        @batch_errors[key] = "batch doesn't exist"
      end
    end
  end

  def build_samples
    case @box.purpose
    when "LOD"
      @box.build_samples(@batches["0"], exponents: 1..8, replicas: 3)

    when "Variants"
      @batches.each_value do |batch|
        @box.build_samples(batch, exponents: [1, 4, 8], replicas: 3)
      end

    when "Challenge"
      @box.build_samples(@batches["0"], exponents: [1, 4, 8], replicas: 18)

      @batches.each do |key, batch|
        @box.build_samples(batch, exponents: [1, 4, 8], replicas: 3) unless key == "0"
      end
    end
  end

  def valid?
    @box.valid?
    validate_batches
    @box.errors.empty? && @batch_errors.empty?
  end

  def save
    if valid?
      @box.save(validate: false)
    else
      false
    end
  end

  private

  def validate_batches
    count = @batches.map { |_, b| b.batch_number }.uniq.size

    case @box.purpose
    when "LOD"
      @batch_errors["0"] = "please select a batch" unless @batches["0"]
      @box.errors.add(:base, "You must select exactly one batch") if count > 1

    when "Variants"
      @box.errors.add(:base, "You must select at least two batches") unless count >= 2

    when "Challenge"
      @batch_errors["0"] = "please select a virus batch" unless @batches["0"]
      @box.errors.add(:base, "You must select at least one distractor batch") unless count >= 2
    end
  end
end
