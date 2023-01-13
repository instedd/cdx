class SamplePresenter
  delegate_missing_to :@sample

  def self.map(samples, format, unblind: false)
    samples.map { |sample| new(sample, format, unblind: unblind) }
  end

  def initialize(sample, format, unblind: false)
    @sample = sample
    @format = format
    @unblind = unblind
  end

  def to_param
    # NOTE: we must manually delegate to_param otherwise named routes aren't
    # generated correctly.
    @sample.to_param
  end

  Box.blind_attribute_names.each do |attr_name|
    define_method attr_name do
      if blinded_attribute?(attr_name) && !@unblind
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
      (box.blinded? && !!box.blind_attribute?(attr_name)) && !@sample.measured_signal
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
      %(<span class="blinded"><i class="icon-visibility_off"></i> Blinded value</span>).html_safe
    else
      "Blinded"
    end
  end
end
