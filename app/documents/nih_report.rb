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
      ["<b>Samples</b>", "#{@samples_report.samples_report_samples.length} samples" + (@samples_report.samples.without_results.count > 0 ? "\n(#{@samples_report.samples.without_results.count} without results)" : "")]
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

    cells = [
      [
        RotatedCell.new(@document, content: ""), 
        TitleCell.new(@document, content: "PREDICTED\nNEGATIVE"), 
        TitleCell.new(@document, content: "PREDICTED\n POSITIVE"), 
        TitleCell.new(@document, content: "TOTAL")
      ],
      [
        RotatedCell.new(@document, content: "ACTUAL\nNEGATIVE"), 
        GreyCell.new(@document, value: @confusion_matrix[:true_negative], title: "True Negative"),
        GreyCell.new(@document, value: @confusion_matrix[:false_positive], title: "False Positive"), 
        TotalCell.new(@document, value: @confusion_matrix[:true_negative] + @confusion_matrix[:false_positive], title: "Actual Negative")
      ],
      [
        RotatedCell.new(@document, content: "ACTUAL\nPOSITIVE"), 
        GreyCell.new(@document, value: @confusion_matrix[:false_negative], title: "False Negative"),
        GreyCell.new(@document, value: @confusion_matrix[:true_positive], title: "True Positive"),
        TotalCell.new(@document, value: @confusion_matrix[:false_negative] + @confusion_matrix[:true_positive], title: "Actual Positive")
      ],
      [
        RotatedCell.new(@document, content: "TOTAL"),
        TotalCell.new(@document, value: @confusion_matrix[:true_negative] + @confusion_matrix[:false_negative], title: "Predicted Negative"),
        TotalCell.new(@document, value: @confusion_matrix[:false_positive] + @confusion_matrix[:true_positive], title: "Predicted Positive"),
        TotalCell.new(@document, value: @confusion_matrix[:true_negative] + @confusion_matrix[:false_positive] + @confusion_matrix[:false_negative] + @confusion_matrix[:true_positive], title: "Total")
      ]
    ]

    text "Confusion Matrix", size: 15, style: :bold, indent_paragraphs: 60
    table(cells, :position => :center, :cell_style => {:border_color => "FFFFFF"})
  end

  def render_svg_plot(svg)
    svg svg, vposition: :center
  end

  private

  class CustomCell < Prawn::Table::Cell
    def initialize(pdf, options={})
      super(pdf, [0, 0], options)
    end

    def draw_content
      @pdf.text @content, align: :center, valign: :center, size: 10, inline_format: true
    end
  end

  class GreyCell < CustomCell
    def initialize(pdf, options={})
      super(pdf, {content: "<font size='18'>#{options[:value]}</font>\n#{options[:title]}"})
    end

    def draw_content
      @pdf.fill_color "eeeeee"
      @pdf.rounded_rectangle [0, natural_content_height], natural_content_width, natural_content_height, 5
      @pdf.fill
      @pdf.fill_color "000000"
      super
      @pdf.fill_color "000000"
    end

    def natural_content_width
      150
    end

    def natural_content_height
      70
    end
  end

  class RotatedCell < CustomCell
    def draw_content
      @pdf.fill_color "666666"
      @pdf.rotate 90, origin: [natural_content_width, natural_content_height] do
        @pdf.move_up 130
        @pdf.text @content, align: :center, valign: :center, size: 10, inline_format: true
      end
    end

    def natural_content_width
      70
    end

    def natural_content_height
      70
    end
  end

  class TitleCell < CustomCell
    def draw_content
      @pdf.fill_color "666666"
      @pdf.move_down 20
      super
      @pdf.fill_color "000000"
    end

    def natural_content_width
      150
    end

    def natural_content_height
      40
    end
  end

  class TotalCell < CustomCell
    def initialize(pdf, options={})
      super(pdf, {content: "<font size='18'>#{options[:value]}</font>\n#{options[:title]}"})
    end

    def draw_content
      @pdf.stroke_color "666666"
      @pdf.fill_color "FFFFFF"
      @pdf.fill_and_stroke_rounded_rectangle [0, natural_content_height], natural_content_width, natural_content_height, 5
      @pdf.fill_color "666666"
      super
    end
    
    def natural_content_width
      150
    end

    def natural_content_height
      70
    end
  end

end