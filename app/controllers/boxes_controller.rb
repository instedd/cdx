require "labels_pdf_renderer"

class BoxesController < ApplicationController
  before_action :load_box, except: %i[index new create bulk_destroy]

  def index
    @can_create = has_access?(@navigation_context.institution, CREATE_INSTITUTION_BOX)

    @boxes = Box.where(institution: @navigation_context.institution)
    @boxes = @boxes.where("uuid LIKE ?", params[:uuid] + "%") if params[:uuid].present?
    @boxes = @boxes.where(purpose: params[:purpose]) if params[:purpose].present?

    @boxes = check_access(@boxes, READ_BOX).order("boxes.created_at DESC")
    @boxes = @boxes.within(@navigation_context.entity, @navigation_context.exclude_subsites)
    @boxes = perform_pagination(@boxes)
  end

  def show
    return unless authorize_resource(@box, READ_BOX)
    @can_delete = has_access?(@box, DELETE_BOX)

    @samples = @box.scrambled_samples.preload(:batch).to_a
  end

  def print
    return unless authorize_resource(@box, READ_BOX)

    pages = []

    # render box label
    pages << render_to_string(
      template: "boxes/barcode.pdf",
      "layout": "layouts/pdf.html",
      locals: { box: @box }
    )

    # render samples' labels
    @box.samples.preload(:sample_identifiers).each do |sample|
      pages << render_to_string(
        template: "samples/barcode.pdf",
        "layout": "layouts/pdf.html",
        locals: { sample: sample }
      )
    end

    begin
      send_data LabelsPdfRenderer.combine(pages),
        type: "application/pdf",
        filename: "cdx_box_#{DateTime.now.strftime("%Y%m%d-%H%M")}.pdf"
    rescue => ex
      Raven.capture_exception(ex)
      redirect_to boxes_path, notice: "There was an error creating the print file."
    end
  end

  def new
    return unless authorize_resource(@navigation_context.institution, CREATE_INSTITUTION_BOX)

    @box_form = BoxForm.build(@navigation_context)
  end

  def create
    return unless authorize_resource(@navigation_context.institution, CREATE_INSTITUTION_BOX)

    @box_form = BoxForm.build(@navigation_context, box_params)
    @box_form.batches = check_access(load_batches, READ_BATCH)

    if @box_form.valid?
      @box_form.build_samples

      if @box_form.save
        redirect_to boxes_path, notice: "Box was successfully created."
        return
      end
    end

    render :new, status: :unprocessable_entity
  end

  def destroy
    return unless authorize_resource(@box, DELETE_BOX)

    @box.destroy
    redirect_to boxes_path, notice: "Box was successfully deleted."
  end

  def bulk_destroy
    boxes = Box.where(id: params[:box_ids])
    return unless authorize_resources(boxes, DELETE_BOX)

    boxes.destroy_all

    redirect_to boxes_path, notice: "Boxes were successfully deleted."
  end

  private

  def load_box
    @box = Box.where(institution: @navigation_context.institution).find(params.fetch(:id))
  end

  def load_batches
    Batch
      .within(@navigation_context.entity, @navigation_context.exclude_subsites)
      .where(batch_number: @box_form.batch_numbers.values.reject(&:blank?))
  end

  def box_params
    if Rails::VERSION::MAJOR == 5 && Rails::VERSION::MINOR == 0
      params.require(:box).permit(:purpose).tap do |allowed|
        allowed[:batch_numbers] = params[:box][:batch_numbers].permit!
      end
    elsif Rails::VERSION::MAJOR >= 5
      params.require(:box).permit(:purpose, batch_numbers: {})
    else
      params.require(:box).permit(:purpose).tap do |allowed|
        allowed[:batch_numbers] = params[:box][:batch_numbers]
      end
    end
  end
end
