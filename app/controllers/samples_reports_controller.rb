require 'zip'

class SamplesReportsController < ApplicationController
  include SamplesReportsHelper

  skip_before_action :verify_authenticity_token

  helper_method :boxes_data
  helper_method :available_institutions
  helper_method :confusion_matrix

  def index
    @can_create = has_access?(@navigation_context.institution, CREATE_INSTITUTION_SAMPLES_REPORT)
    @can_delete = has_access?(SamplesReport, DELETE_SAMPLES_REPORT)

    @samples_reports = SamplesReport.where(institution: @navigation_context.institution)
    @samples_reports = check_access(@samples_reports, READ_SAMPLES_REPORT).order('samples_reports.created_at DESC')

    # filter by search params
    @samples_reports = @samples_reports.partial_name(params[:name])
    @samples_reports = @samples_reports.partial_sample_uuid(params[:sample_uuid])
    @samples_reports = @samples_reports.partial_box_uuid(params[:box_uuid])
    @samples_reports = @samples_reports.partial_batch_number(params[:batch_number])

    # paginate samples report
    @samples_reports = perform_pagination(@samples_reports)
  end

  def new
    @samples_report = SamplesReport.new({
      institution: @navigation_context.institution,
      site: @navigation_context.site
    })

    @boxes = []

    prepare_for_institution_and_authorize(@samples_report, CREATE_INSTITUTION_SAMPLES_REPORT)
  end

  def create
    @institution = @navigation_context.institution
    return unless authorize_resource(@institution, CREATE_INSTITUTION_SAMPLES_REPORT)

    @samples_report = SamplesReport.new()
    @samples_report.institution = @institution
    @samples_report.site = @navigation_context.site
    @samples_report.name = params[:samples_report][:name]

    samples_report_samples = []
    if params[:samples_report][:box_ids]
      params[:samples_report][:box_ids].each do |box_id|
        box = Box.find(box_id)
        box = check_access(box, READ_BOX)
        next if box.nil?
        box.samples.each do |sample|
          samples_report_samples  << SamplesReportSample.new(samples_report: @samples_report, sample: sample)
        end
      end
    end

    @samples_report.samples_report_samples = samples_report_samples

    if @samples_report.save
      @samples_report.calculate_lod_and_lob
      redirect_to samples_reports_path, notice: 'Report was successfully created.'
    else
      render action: 'new'
    end
  end

  def print
    # convert json param to hash
    json_params = JSON.parse(params[:json])
    samples_report = SamplesReport.find(json_params["id"])

    return unless authorize_resource(samples_report, READ_SAMPLES_REPORT)

    purpose = samples_report.samples[0].box.purpose

    options = {
      :samples_report => samples_report,
      :purpose => purpose
    }

    if purpose == "Challenge"
      options[:threshold] = json_params["threshold"].to_f
      options[:auc] = json_params["auc"].to_f
      options[:threshold_tpr] = json_params["threshold_tpr"].to_f
      options[:threshold_fpr] = json_params["threshold_fpr"].to_f
    else
      options[:threshold] = 0.0
    end

    options[:confusion_matrix] = confusion_matrix(samples_report.samples, options[:threshold])

    options[:measured_signal_svg] = json_params["measured_signal_svg"]
    options[:specific_svg] = json_params["specific_svg"]

    send_data NihReport.new(options).render,
      filename: "#{samples_report.name}.pdf",
      type: "application/pdf",
      disposition: "inline"
  end

  def show
    @samples_report = SamplesReport.find(params[:id])
    return unless authorize_resource(@samples_report, READ_SAMPLES_REPORT)
    @reports_data = measured_signal_data(@samples_report)
    @samples_without_results_count = @samples_report.samples.without_results.count
    @purpose = @samples_report.samples[0].box.purpose
    @max_signal = @reports_data.reduce(0) { |a, e| e[:max] > a ? e[:max] : a }
    @can_delete = has_access?(@samples_report, DELETE_SAMPLES_REPORT)
  end

  def delete
    @samples_report = SamplesReport.find(params[:id])
    return unless authorize_resource(@samples_report, DELETE_SAMPLES_REPORT)

    @samples_report.destroy

    redirect_to samples_reports_path, notice: 'Report was successfully deleted.'
  end

  def bulk_destroy
    samples_reports_ids = params[:samples_report_ids]

    if samples_reports_ids.blank?
      redirect_to samples_reports_path, notice: 'Select at least one report to destroy.'
      return
    end

    samples_reports = SamplesReport.where(id: samples_reports_ids)
    return unless authorize_resources(samples_reports, DELETE_SAMPLES_REPORT)

    samples_reports.destroy_all

    redirect_to samples_reports_path, notice: 'Reports were successfully deleted.'
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
    samples_report = SamplesReport.find(params[:samples_report_id])
    confusion_matrix = confusion_matrix(samples_report.samples, threshold.to_f)
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

  def measured_signal_data(samples_report)
    measurements = Hash.new { |hash, key| hash[key] = [] }
    truths = Hash.new { true }
    purpose = samples_report.samples[0].box.purpose

    samples_report.samples.map do |s|
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
