class LabelPdf < BasePdf
  def document
    @document ||= Prawn::Document.new(
      top_margin: 1.8,
      left_margin: 2.4,
      right_margin: 2,
      bottom_margin: 0,
      page_size: [72, 72], # 1in == 72pt
      print_scaling: :none
    )
  end

  def setup
    font_families.update("RobotoMono" => {
      normal: assets_path.join("fonts/Roboto/RobotoMono-Regular.ttf"),
      bold: assets_path.join("fonts/Roboto/RobotoMono-Bold.ttf"),
    })
    font "RobotoMono"
    font_size 5.3
    default_leading 0
  end

  protected

  def render_uuid(uuid)
    svg qrcode_svg(uuid), width: 27.4, height: 27.4, position: :center, enable_web_requests: false
    move_down 1.6
    text_line uuid, align: :center, leading: 0.2
    move_up 0.6
  end

  def qrcode_svg(value)
    barcode = Barby::QrCode.new(value, level: :m)
    outputter = Barby::SvgOutputter.new(barcode)
    outputter.xdim = 2
    outputter.margin = 0
    outputter.to_svg
  end

  def render_sample_details(sample)
    text_lines [
      "I.N. #{sample.isolate_name}".truncate(22),
      "I.M. #{sample.inactivation_method}".truncate(22),
      "P.D. #{sample.date_produced == "Blinded" ? "Blinded" : sample.date_produced.strftime("%m/%d/%Y")}",
    ], leading: -0.5
  end

  def render_cdx_logo
    bounding_box [0.6, 7], width: bounds.right do
      image assets_path.join("images/cdx-logo-bw.png"), width: 8.9, height: 4.1
      move_up 4.5
      text "https://cdx.io", indent_paragraphs: 10.8, character_spacing: -0.07, size: 4.1
    end
  end

  def text_lines(lines, leading: -0.5, **options)
    lines.each_with_index do |line, index|
      text_line line, leading: leading, **options
    end
  end

  def text_line(line, **options)
    text line, character_spacing: -0.2, **options
  end
end
