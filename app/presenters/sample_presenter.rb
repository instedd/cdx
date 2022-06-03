class SamplePresenter
  delegate_missing_to :@sample

  def self.map(samples, format)
    samples.map { |sample| new(sample, format) }
  end

  def initialize(sample, format)
    @sample = sample
    @format = format
  end

  Box.blind_attribute_names.each do |attr_name|
    define_method attr_name do
      if blinded_attribute?(attr_name)
        blinded_value
      else
        @sample.__send__(attr_name)
      end
    end
  end

  def blinded?
    !!sample.box.try(&:blinded?)
  end

  def blinded_attribute?(attr_name)
    if box = @sample.box
      box.blinded? && !!box.blind_attribute?(attr_name)
    else
      false
    end
  end

  def blinded_attribute(attr_name)
    if blinded_attribute?(attr_name)
      blinded_value
    else
      yield
    end
  end

  def blinded_value
    if @format.html?
      %(<div class="blinded"><i class="icon-visibility_off"></i> Blinded value</div>).html_safe
    else
      "Blinded"
    end
  end
end
