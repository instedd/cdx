class SamplesReportsController < ApplicationController
  include SamplesReportsHelper

  helper_method :boxes_data
  helper_method :available_institutions

  def index
    @can_create = has_access?(@navigation_context.institution, CREATE_INSTITUTION_SAMPLES_REPORT)
    @can_delete = has_access?(SamplesReport, DELETE_SAMPLES_REPORT)

    @samples_reports = SamplesReport.where(institution: @navigation_context.institution)
    @samples_reports = check_access(@samples_reports, READ_SAMPLES_REPORT).order('samples_reports.created_at DESC')
  
    # Filter by search params

    @samples_reports = @samples_reports.partial_name(params[:name])
    @samples_reports = @samples_reports.partial_sample_uuid(params[:sample_uuid])
    @samples_reports = @samples_reports.partial_box_uuid(params[:box_uuid])
    @samples_reports = @samples_reports.partial_batch_number(params[:batch_number])

    #paginate samples report
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
      redirect_to samples_reports_path, notice: 'Box report was successfully created.'
    else
      render action: 'new'
    end
  end

  def show
    @samples_report = SamplesReport.find(params[:id])
    return unless authorize_resource(@samples_report, READ_SAMPLES_REPORT)
    @can_delete = has_access?(@samples_report, DELETE_SAMPLES_REPORT)
  end

  def delete
    @samples_report = SamplesReport.find(params[:id])
    return unless authorize_resource(@samples_report, DELETE_SAMPLES_REPORT)
  
    @samples_report.destroy
    
    redirect_to samples_reports_path, notice: 'Box report was successfully deleted.'
  end
  
  def bulk_destroy
    samples_reports_ids = params[:samples_report_ids]
  
    if samples_reports_ids.blank?
      redirect_to samples_reports_path, notice: 'Select at least one box report to destroy.'
      return
    end
  
    samples_reports = SamplesReport.where(id: samples_reports_ids)
    return unless authorize_resources(samples_reports, DELETE_SAMPLES_REPORT)
  
    samples_reports.destroy_all
  
    redirect_to samples_reports_path, notice: 'Box reports were successfully deleted.'
  end

  def find_box
    @navigation_context = NavigationContext.new(nil, params[:context])

    @boxes = Box
      .within(@navigation_context.entity, @navigation_context.exclude_subsites)
      .left_joins(:box_transfers)
      .where(box_transfers: {id: nil})
      .autocomplete(params[:uuid])
      .order("created_at DESC")
      .count_samples
      .count_samples_without_results
      .limit(5)
    
    @boxes = check_access(@boxes, READ_BOX)

    render json: { boxes: boxes_data(@boxes) }
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

end
