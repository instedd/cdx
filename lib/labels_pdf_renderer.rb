require_relative "./multipage_pdf_renderer"

module LabelsPdfRenderer
  def self.combine(pages)
    MultipagePdfRenderer.combine(pages, options)
  end

  def self.options
    {
      margin: {
        top: 0,
        bottom: 0,
        left: 0,
        right: 0,
      },
      page_width: "1in",
      page_height: "1in",
    }
  end
end
