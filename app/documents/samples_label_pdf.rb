class SamplesLabelPdf < LabelPdf
  def initialize(samples)
    format = Mime::Type.lookup("application/pdf")
    @samples = samples.map { |sample| SamplePresenter.new(sample, format)  }
  end

  def template
    @samples.each_with_index do |sample, index|
      start_new_page unless index == 0
      render_uuid(sample.uuid)
      render_sample_details(sample)
      render_cdx_logo
    end
  end
end
