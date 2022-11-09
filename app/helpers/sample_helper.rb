module SampleHelper
  def loinc_code_description(loinc_code)
    if loinc_code.nil?
      ""
    else
      loinc_code.description
    end
  end

  def concentration_formatting(concentration)
    if concentration.to_s.length > 8
      ("%g" % concentration.to_s).to_s
    else
      concentration
    end
  end
end
