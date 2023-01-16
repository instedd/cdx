class SampleLabelPdf < LabelPdf
  def initialize(sample)
    @sample = SamplePresenter.new(sample, Mime::Type.lookup("application/pdf"))
  end

  def template
    render_uuid(@sample.uuid)
    render_sample_details(@sample)
    render_cdx_logo
  end
end
