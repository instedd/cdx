class BoxLabelPdf < SamplesLabelPdf
  def initialize(box, samples)
    @box = box
    super(samples)
  end

  def template
    render_uuid(@box.uuid)
    render_box_details
    render_cdx_logo

    start_new_page
    super
  end

  protected

  def render_box_details
    text_lines [
      @box.institution.name.truncate(22),
      "#{@box.purpose} (#{@samples.size} samples)",
    ]
  end
end
