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

    @samples = @box.scrambled_samples.preload(:batch, :sample_identifiers)
  end

  def inventory
    return unless authorize_resource(@box, READ_BOX)

    @samples = @box.samples.preload(:batch, :sample_identifiers)

    respond_to do |format|
      format.csv do
        @filename = "cdx_box_inventory_#{@box.uuid}.csv"
      end
    end
  end

  def print
    return unless authorize_resource(@box, READ_BOX)

    render pdf: "cdx_box_#{@box.uuid}",
      template: "boxes/print.pdf",
      layout: "layouts/pdf.html",
      locals: {
        box: @box,
        samples: @box.samples.preload(:batch, :sample_identifiers),
      },
      margin: { top: 0, bottom: 0, left: 0, right: 0 },
      page_width: "1in",
      page_height: "1in",
      show_as_html: params.key?("debug")
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
      .where(uuid: @box_form.batch_uuids.values.reject(&:blank?))
  end

  def box_params
    if Rails::VERSION::MAJOR == 5 && Rails::VERSION::MINOR == 0
      params.require(:box).permit(:purpose).tap do |allowed|
        allowed[:batch_uuids] = params[:box][:batch_uuids].permit!
      end
    elsif Rails::VERSION::MAJOR >= 5
      params.require(:box).permit(:purpose, batch_uuids: {})
    else
      params.require(:box).permit(:purpose).tap do |allowed|
        allowed[:batch_uuids] = params[:box][:batch_uuids]
      end
    end
  end
end
