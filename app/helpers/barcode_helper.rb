require 'barby'
require 'barby/barcode/code_93'
require 'barby/barcode/code_128'
require 'barby/barcode/qr_code'
require 'barby/outputter/html_outputter'
require 'barby/outputter/png_outputter'
require 'barby/outputter/svg_outputter'

module BarcodeHelper
  def barcode(code)
    barcode = Barby::Code93.new(code)
    Barby::HtmlOutputter.new(barcode).to_html.html_safe
  end

  def image_barcode(code)
    barcode = Barby::Code93.new(code)
    file = Tempfile.new(['barcode', '.png'])
    outputter = Barby::PngOutputter.new(barcode)
    outputter.xdim = 2
    file.write outputter.to_png
    file.rewind
    yield file
    file.close
    file.unlink
  end

  def barcode_img_data_url(code)
    barcode = Barby::QrCode.new(code, level: :m)

    outputter = Barby::PngOutputter.new(barcode)
    outputter.xdim = 2
    # outputter.height = 50  # defaults: 100
    outputter.margin = 0
    outputter.to_image.to_data_url
  end

  def barcode_svg_data_url(code)
    barcode = Barby::QrCode.new(code, level: :m)
    outputter = Barby::SvgOutputter.new(barcode)
    outputter.xdim = 2
    outputter.margin = 0
    "data:image/svg+xml;base64,#{Base64.encode64(outputter.to_svg)}"
  end
end
