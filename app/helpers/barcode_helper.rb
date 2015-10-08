module BarcodeHelper
  def barcode(code)
    barcode = Barby::Code93.new(code)
    Barby::HtmlOutputter.new(barcode).to_html.html_safe
  end
end
