class BoxReportsController < ApplicationController
  include BoxReportsHelper

  helper_method :boxes_data
  helper_method :available_institutions
  helper_method :confusion_matrix

  def index
    @can_create = has_access?(@navigation_context.institution, CREATE_INSTITUTION_BOX_REPORT)
    @can_delete = has_access?(BoxReport, DELETE_BOX_REPORT)

    @box_reports = BoxReport.where(institution: @navigation_context.institution)
    @box_reports = check_access(@box_reports, READ_BOX_REPORT).order('box_reports.created_at DESC')
  
    # Filter by search params

    @box_reports = @box_reports.partial_name(params[:name])
    @box_reports = @box_reports.partial_sample_uuid(params[:sample_uuid])
    @box_reports = @box_reports.partial_box_uuid(params[:box_uuid])
    @box_reports = @box_reports.partial_batch_number(params[:batch_number])

    #paginate samples report
    @box_reports = perform_pagination(@box_reports)
  end
  
  def new
    @box_report = BoxReport.new({
      institution: @navigation_context.institution,
      site: @navigation_context.site
    })

    @boxes = []
    
    prepare_for_institution_and_authorize(@box_report, CREATE_INSTITUTION_BOX_REPORT)
  end

  def create
    @institution = @navigation_context.institution
    return unless authorize_resource(@institution, CREATE_INSTITUTION_BOX_REPORT)

    @box_report = BoxReport.new()
    @box_report.institution = @institution
    @box_report.site = @navigation_context.site
    @box_report.name = params[:box_report][:name]
    
    box_report_samples = []
    if params[:box_report][:box_ids] 
      params[:box_report][:box_ids].each do |box_id|
        box = Box.find(box_id)
        box = check_access(box, READ_BOX)
        next if box.nil?
        box.samples.each do |sample|
          box_report_samples  << BoxReportSample.new(box_report: @box_report, sample: sample)
        end
      end
    end

    @box_report.box_report_samples = box_report_samples

    if @box_report.save
      redirect_to box_reports_path, notice: 'Box report was successfully created.'
    else
      render action: 'new'
    end
  end


  def show
    @box_report = BoxReport.find(params[:id])
    return unless authorize_resource(@box_report, READ_BOX_REPORT)
    @reports_data = measured_signal_data(@box_report)
    @samples_without_results_count = @box_report.samples.without_results.count
    @purpose = @box_report.samples[0].box.purpose
    
    if params[:display] == "pdf"
      gon.box_report_id = @box_report.id
      gon.box_report_name = @box_report.name
      gon.purpose = @purpose
      gon.threshold = params[:threshold]
      gon.min_threshold = params[:minthreshold]
      gon.max_threshold = params[:maxthreshold]
      render "_pdf_report", layout: false
    else
      @max_signal = @reports_data.reduce(0) { |a, e| e[:max] > a ? e[:max] : a }
      @can_delete = has_access?(@box_report, DELETE_BOX_REPORT)
    end
  end

  def delete
    @box_report = BoxReport.find(params[:id])
    return unless authorize_resource(@box_report, DELETE_BOX_REPORT)
  
    @box_report.destroy
    
    redirect_to box_reports_path, notice: 'Box report was successfully deleted.'
  end
  
  def bulk_destroy
    box_reports_ids = params[:box_report_ids]
  
    if box_reports_ids.blank?
      redirect_to box_reports_path, notice: 'Select at least one box report to destroy.'
      return
    end
  
    box_reports = BoxReport.where(id: box_reports_ids)
    return unless authorize_resources(box_reports, DELETE_BOX_REPORT)
  
    box_reports.destroy_all
  
    redirect_to box_reports_path, notice: 'Box reports were successfully deleted.'
  end

  def find_box
    @navigation_context = NavigationContext.new(nil, params[:context])

    @boxes = Box
      .within(@navigation_context.entity, @navigation_context.exclude_subsites)
      .left_joins(:box_transfers)
      .autocomplete(params[:uuid])
      .order("created_at DESC")
      .count_samples
      .count_samples_without_results
      .limit(5)

    @boxes = check_access(@boxes, READ_BOX)

    render json: { boxes: boxes_data(@boxes) }
  end

  def update_threshold
    threshold = params[:threshold]
    box_report = BoxReport.find(params[:box_report_id])
    confusion_matrix = confusion_matrix(box_report.samples, threshold.to_f)
    render json: { threshold: threshold, confusion_matrix: confusion_matrix }
  end

  private

  def boxes_data(boxes)
    if boxes
      boxes.map { |box|
        {
          id: box.id,
          uuid: box.uuid,
          hasQcReference: box.samples.any?(&:has_qc_reference?),
          preview: render_to_string(partial: "boxes/preview_for_report", locals: { box: box }),
          samplesWithoutResults: box.count_samples_without_results > 0
        }
      }
    else
      []
    end
  end

  def measured_signal_data(box_report)
    measurements = Hash.new { |hash, key| hash[key] = [] }
    truths = Hash.new { true }
    purpose = box_report.samples[0].box.purpose

    box_report.samples.map do |s|
      if s.measured_signal
        label = purpose == "LOD" ? s.concentration : s.batch_number + "-" + s.concentration.to_s
        measurements[label] << s.measured_signal
        truths[label] = s.distractor
      end
    end

    measurements.sort_by { |k, _| k }.map do |label, signals|
      avg = signals.sum / signals.size
      errors = signals.map { |s| (s - avg).abs }
      max = avg + Math.sqrt(errors.sum / errors.size)
      {
        label: label,
        average: [avg],
        measurements: signals,
        errors: errors,
        isDistractor: truths[label],
        max: max
      }
    end
  end

  def confusion_matrix(samples, threshold)
    confusion_matrix = Hash.new{0}
    
    samples.each do |s|
      next unless s.measured_signal
      if s.concentration == 0 || s.distractor
        s.measured_signal > threshold ? confusion_matrix[:false_positive] += 1 : confusion_matrix[:true_negative] += 1
      else
        s.measured_signal > threshold ? confusion_matrix[:true_positive] += 1 : confusion_matrix[:false_negative] += 1
      end
    end

    confusion_matrix[:actual_positive] = confusion_matrix[:true_positive] + confusion_matrix[:false_negative]
    confusion_matrix[:actual_negative] = confusion_matrix[:true_negative] + confusion_matrix[:false_positive]
    confusion_matrix[:predicted_positive] = confusion_matrix[:true_positive] + confusion_matrix[:false_positive]
    confusion_matrix[:predicted_negative] = confusion_matrix[:true_negative] + confusion_matrix[:false_negative]
    confusion_matrix[:total] = confusion_matrix[:actual_positive] + confusion_matrix[:actual_negative]

    confusion_matrix
  end


end
