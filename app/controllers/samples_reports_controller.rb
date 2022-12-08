class SamplesReportsController < ApplicationController
  include SamplesReportsHelper

  helper_method :boxes_data
  helper_method :available_institutions

  def index
    @can_create = has_access?(@navigation_context.institution, CREATE_INSTITUTION_SAMPLES_REPORT)
  
    @samples_reports = SamplesReport.where(institution: @navigation_context.institution)
    @samples_reports = check_access(@samples_reports, READ_SAMPLES_REPORT).order('created_at DESC')
  
    # Filter by search params
    @samples_reports = @samples_reports.where("name LIKE concat('%', ?, '%')", params[:name]) unless params[:name].blank?
    @samples_reports = @samples_reports.joins(samples: :sample_identifiers).where("sample_identifiers.uuid LIKE concat('%', ?, '%')", params[:sample_uuid]) unless params[:sample_uuid].blank?
    @samples_reports = @samples_reports.joins("LEFT JOIN samples_report_samples ON samples_report_samples.samples_report_id = samples_reports.id 
                                               LEFT JOIN samples ON samples_report_samples.sample_id = samples.id 
                                               LEFT JOIN boxes ON boxes.id = samples.box_id")
                                        .where("boxes.uuid LIKE concat('%', ?, '%')", params[:box_uuid])
                                        .group(:samples_report_id) unless params[:box_uuid].blank?
    @samples_reports = @samples_reports.joins("LEFT JOIN samples_report_samples ON samples_report_samples.samples_report_id = samples_reports.id 
                                        LEFT JOIN samples ON samples_report_samples.sample_id = samples.id 
                                        LEFT JOIN batches ON batches.id = samples.batch_id")
                                 .where("batches.batch_number LIKE concat('%', ?, '%')", params[:batch_number])
                                 .group(:samples_report_id) unless params[:batch_number].blank?

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
    @boxes = [] # For form reloading in case of validation error
    if params[:samples_report][:boxes_attributes]
      @boxes_p = params[:samples_report][:boxes_attributes]
      @boxes_p.each do |box_param|
        box_id = @boxes_p[box_param][:box_id]
        box = Box.find_by_id(box_id)
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
    @samples_report = SamplesReport.find_by_id(params[:id])
    return unless authorize_resource(@samples_report, READ_SAMPLES_REPORT)
    @can_delete = has_access?(@samples_report, DELETE_SAMPLES_REPORT)
  end

  def delete
    @samples_report = SamplesReport.find_by_id(params[:id])
    return unless authorize_resource(@samples_report, DELETE_SAMPLES_REPORT)
  
    SamplesReport.destroy(params[:id])
    
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

    uuid = params[:uuid]
    full_uuid = uuid.size == 36
    @boxes = Box
      .within(@navigation_context.entity, @navigation_context.exclude_subsites)
      .left_joins(:box_transfers)
      .where(box_transfers: {id: nil})
      .autocomplete(uuid)
      .order("created_at DESC")
      .count_samples
      .count_samples_without_results
      .limit(5)

    @boxes = check_access(@boxes, READ_BOX)

    render json: { boxes: boxes_data(@boxes) }
  end


  private

  def boxes_data(boxes)
    boxes.map { |box|
      {
        id: box.id,
        uuid: box.uuid,
        hasQcReference: box.samples.any?(&:has_qc_reference?),
        preview: render_to_string(partial: "boxes/preview_for_report", locals: { box: box }),
        samplesWithoutResults: box.samples_without_results_count>0 ? true : false 
      }
    }
  end

end
