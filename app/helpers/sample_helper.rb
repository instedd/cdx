module SampleHelper
  def loinc_code_description(loinc_code)
    if loinc_code.nil?
      ""
    else
      loinc_code.description
    end
  end
end