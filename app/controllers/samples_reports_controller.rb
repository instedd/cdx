class SamplesReportsController < ApplicationController
  include SamplesReportsHelper

  helper_method :boxes_data
  helper_method :available_institutions

  def index
    @can_create = true # has_access?(@navigation_context.institution, CREATE_INSTITUTION_BATCH)
  
    @samples_reports = SamplesReport.where(institution: @navigation_context.institution)
    #@batches = check_access(@batches, READ_BATCH).order('created_at DESC')
  
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

    #paginate batches
    @samples_reports = perform_pagination(@samples_reports)
  end
  
  def new
    @samples_report = SamplesReport.new({
      institution: @navigation_context.institution,
      site: @navigation_context.site
    })

    @boxes = []
    
    #@batch_form = BatchForm.for(batch)
    #prepare_for_institution_and_authorize(@batch_form, CREATE_INSTITUTION_BATCH)
  end

  def create
    @institution = @navigation_context.institution
    #return unless authorize_resource(institution, CREATE_INSTITUTION_BATCH)

    @samples_report = SamplesReport.new()
    @samples_report.institution = @institution
    @samples_report.site = @navigation_context.site
    @samples_report.name = params[:samples_report][:name]
    @samples_report.threshold = params[:samples_report][:threshold]
    @boxes_p = params[:transfer_package][:box_transfers_attributes]
    @boxes_p.each do |box_param|
      box_id = @boxes_p[box_param][:box_id]
      box = Box.find_by_id(box_id)
      box.samples.each do |sample|
        @samples_report.samples_report_samples << SamplesReportSample.new(samples_report: @samples_report, sample: sample)
      end
    end

    if @samples_report.save
      redirect_to samples_reports_path, notice: 'Box report was successfully created.'
    else
      render action: 'new'
    end

    #batch = Batch.new(batch_params.merge({
    #  institution: institution,
    #  site: @navigation_context.site
    #}))
    #@batch_form = BatchForm.for(batch)
    #@batch_form.samples_quantity = batch_samples_quantity_params

  end

  def show
    @samples_report = SamplesReport.find_by_id(params[:id])
    #return unless authorize_resource(@samples_report, READ_BOX)
    #@can_delete = has_access?(@box, DELETE_BOX)

  end

  def delete
    #return unless authorize_resource(@batch, DELETE_BATCH)
  
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
    #return unless authorize_resources(batches, DELETE_BATCH)
  
    samples_reports.destroy_all
  
    redirect_to samples_reports_path, notice: 'Box reports were successfully deleted.'
  end

  private

  def boxes_data(boxes)
    boxes.map { |box|
      {
        id: box.id,
        uuid: box.uuid,
        hasQcReference: box.samples.any?(&:has_qc_reference?),
        preview: render_to_string(partial: "boxes/preview", locals: { box: box }),
      }
    }
  end

end
