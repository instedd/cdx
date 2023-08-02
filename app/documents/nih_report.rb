class NihReport < BasePdf
  include SamplesReportsHelper
  
  def initialize(options = {})
    @samples_report = options[:samples_report]
    @purpose = options[:purpose]
    @confusion_matrix = options[:confusion_matrix]
    @options = options
  end

  def document
    @document ||= Prawn::Document.new(
      top_margin: 30,
      left_margin: 20,
      right_margin: 20,
      bottom_margin: 30,
      page_size: [842, 595], # A4
      print_scaling: :none
    )
  end
  
  def setup
    font_families.update("OpenSans" => {
      normal: assets_path.join("fonts/OpenSans/OpenSans-Regular.ttf"),
      bold: assets_path.join("fonts/OpenSans/OpenSans-Bold.ttf"),
    })
    font "OpenSans"
    font_size 5.3
    default_leading 0
  end

  def template
    render_header
    render_report_details
    render_confussion_matrix
    start_new_page
    render_header
    render_svg_plot(@options[:measured_signal_svg])
    start_new_page
    render_header
    render_svg_plot(@options[:specific_svg])
  end

  def render
    setup
    template
    document.render
  end

  protected

  def render_header
    bounding_box [bounds.left, bounds.top], width: bounds.right do
      text "Report: #{@samples_report.name}", character_spacing: -0.07, size: 10, position: :right, color: "999999", indent_paragraphs: 600
      move_down 3
      text "Created at #{@samples_report.created_at.strftime(I18n.t('date.input_format.pattern'))}", character_spacing: -0.07, size: 10, position: :right, color: "999999", indent_paragraphs: 600
      move_up 25
      image assets_path.join("images/cdx-logo-bw.png"), width: 50, position: 540
      move_down 30
    end
  end

  def render_report_details
    
    data = [
      ["<b>Purpose</b>", @purpose],
      ["<b>Samples</b>", "#{@samples_report.samples_report_samples.length} samples" + (@samples_report.samples.without_results.count > 0 ? "\n(#{@samples_report.samples.without_results.count} without results)" : "")],
    ]

    if @purpose == "LOD"
      data << ["<b>LOB</b>", @samples_report.lob&.round(3)]
      data << ["<b>LOD</b>", @samples_report.lod&.round(3)]
    elsif @purpose == "Challenge"
      data << ["<b>Threshold</b>", @options[:threshold]&.round(3)]
      data << ["<b>Computed ROC AUC</b>", @options[:auc]&.round(3)]
      data << ["<b>Threshold's TPR</b>", @options[:threshold_tpr]&.round(3)]
      data << ["<b>Threshold's FPR</b>", @options[:threshold_fpr]&.round(3)]
    end

    # transpose data
    data = data.transpose

    text "Summary", size: 15, style: :bold, indent_paragraphs: 60
    move_down 10

    table data, position: :center, width: 650 do
      cells.style do |cell|
        cell.border_width = 10
        cell.border_color = "FFFFFF"
        cell.padding = 5
        cell.size = 10
        cell.inline_format = true 
        cell.align = :center
      end
    end
    
    move_down 30
  end

  def render_confussion_matrix
    move_down 10
    data = [
      ["", "PREDICTED\nNEGATIVE", "PREDICTED\n POSITIVE", "TOTAL"],
      [
        "ACTUAL\nNEGATIVE", 
        "<font size='18'>#{@confusion_matrix[:true_negative]}</font>\nTrue Negative",
        "<font size='18'>#{@confusion_matrix[:false_positive]}</font>\nFalse Positive",
        "<font size='18'>#{@confusion_matrix[:true_negative] + @confusion_matrix[:false_positive]}</font>\nActual Negative"
      ],
      [
        "ACTUAL\nPOSITIVE",
        "<font size='18'>#{@confusion_matrix[:false_negative]}</font>\nFalse Negative",
        "<font size='18'>#{@confusion_matrix[:true_positive]}</font>\nTrue Positive",
        "<font size='18'>#{@confusion_matrix[:false_negative] + @confusion_matrix[:true_positive]}</font>\nActual Positive"
      ],
      [
        "TOTAL",
        "<font size='18'>#{@confusion_matrix[:true_negative] + @confusion_matrix[:false_negative]}</font>\nPredicted Negative",
        "<font size='18'>#{@confusion_matrix[:false_positive] + @confusion_matrix[:true_positive]}</font>\nPredicted Positive",
        "<font size='18'>#{@confusion_matrix[:true_negative] + @confusion_matrix[:false_positive] + @confusion_matrix[:false_negative] + @confusion_matrix[:true_positive]}</font>\nTotal"
      ],
    ]

    inside_colors = [
      "FFFFFF", "FFFFFF", "FFFFFF", "FFFFFF",
      "FFFFFF", "F0F0F0", "F0F0F0", "FFFFFF",
      "FFFFFF", "F0F0F0", "F0F0F0", "FFFFFF",
      "FFFFFF", "FFFFFF", "FFFFFF", "FFFFFF",
    ]
    text_colors = [
      "666666", "666666", "666666", "666666",
      "666666", "000000", "000000", "666666",
      "666666", "000000", "000000", "666666",
      "666666", "666666", "666666", "666666",
    ]
    text_rotate = [
      0, 0, 0, 0,
      90, 0, 0, 0,
      90, 0, 0, 0,
      90, 0, 0, 0,
    ]
    cell_widths = [
      70, 200, 200, 100,
      70, 200, 200, 100,
      70, 200, 200, 100,
      70, 200, 200, 100,
    ]
    cell_heights = [
      40, 40, 40, 40,
      70, 70, 70, 70,
      70, 70, 70, 70,
      50, 50, 50, 50,
    ]

    text "Confusion Matrix", size: 15, style: :bold, indent_paragraphs: 60
    move_down 30

    i=0
    table data, position: :center do
      cells.style do |cell|
        cell.border_width = 10
        cell.border_color = "FFFFFF"
        cell.background_color = inside_colors[i]
        cell.padding_left = 5
        cell.padding_right = 5
        cell.padding_top = 2
        cell.padding_bottom = 2
        cell.size = 10
        cell.align = :center
        cell.valign = :center
        cell.text_color = text_colors[i]
        cell.rotate = text_rotate[i]
        cell.rotate_around = :center
        cell.height = cell_heights[i]
        cell.width = cell_widths[i]
        cell.inline_format = true 
        i+=1
      end
    end
    @current_cursor = cursor

    rounded_rectangle [0, @current_cursor + 50], 50, @current_cursor - cursor + 10, 10
  end

  def render_svg_plot(svg)
    svg URI.unescape(svg), vposition: :center
  end

end