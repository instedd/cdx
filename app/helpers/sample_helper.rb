module SampleHelper
  def loinc_code_description(loinc_code)
    if loinc_code.nil?
      ""
    else
      loinc_code.description
    end
  end

  def blinded?(sample)
    !!sample.box.try(&:blinded?)
  end

  def blinded_attribute?(sample, attr_name)
    if box = sample.box
      box.blinded? && !!box.blind_attribute?(attr_name)
    else
      false
    end
  end

  def blinded_attribute(sample, attr_name, value: nil)
    if blinded_attribute?(sample, attr_name)
      value || blinded_value
    else
      sample.__send__(attr_name)
    end
  end

  def blinded_value
    %(<div class="blinded"><i class="icon-visibility_off"></i> Blinded value</div>).html_safe
  end
end
