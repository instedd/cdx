class BoxesController < ApplicationController
  before_action :load_box, except: %i[index new create]

  def index
    @can_create = has_access?(@navigation_context.institution, CREATE_INSTITUTION_BOX)

    @boxes = Box.where(institution: @navigation_context.institution)
    @boxes = @boxes.where("uuid LIKE ?", params[:uuid] + "%") if params[:uuid].present?
    @boxes = @boxes.where(purpose: params[:purpose]) if params[:purpose].present?

    @boxes = check_access(@boxes, READ_BOX).order('created_at DESC')
    @boxes = @boxes.within(@navigation_context.entity, @navigation_context.exclude_subsites)
    @boxes = perform_pagination(@boxes)
  end

  def new
    return unless authorize_resource(@navigation_context.institution, CREATE_INSTITUTION_BOX)
    @can_update = true

    @box = Box.new(new_box_params)
  end

  def edit
    return unless authorize_resource(@box, READ_BOX)
    @can_update = false
    @can_delete = has_access?(@box, DELETE_BOX)
  end

  def create
    return unless authorize_resource(@navigation_context.institution, CREATE_INSTITUTION_BOX)

    @box = Box.new(new_box_params)
    @box.attributes = box_params

    batch_uuids = params.dig(:box, :batch_uuids).to_a

    case @box.purpose
    when "LOD"
      batch = Batch.find_by(uuid: batch_uuids)
      return unless authorize_resource(batch, READ_BATCH)
      @box.build_samples(batch, exponents: 1..8, replicas: 3)

    when "Variants"
      batches = check_access(Batch.where(uuid: batch_uuids), READ_BATCH)
      batches.each do |batch|
        @box.build_samples(batch, exponents: [1, 4, 8], replicas: 3)
      end

    when "Challenge"
      batch = Batch.find_by(uuid: batch_uuids.shift)
      return unless authorize_resource(batch, READ_BATCH)
      @box.build_samples(batch, exponents: [1, 4, 8], replicas: 18)

      batches = check_access(Batch.where(uuid: batch_uuids), READ_BATCH)
      batches.each do |batch|
        @box.build_samples(batch, exponents: [1, 4, 8], replicas: 3)
      end
    end

    if @box.save
      redirect_to boxes_path, notice: "Box was successfully created."
    else
      render :new
    end
  end

  # def update
  #   return unless authorize_resource(@box, UPDATE_BOX)

  #   if @box.update(box_params)
  #     redirect_to boxes_path, notice: "Box was successfully updated."
  #   else
  #     render :edit
  #   end
  # end

  def destroy
    return unless authorize_resource(@box, DELETE_BOX)

    @box.destroy
    redirect_to boxes_path, notice: "Box was successfully deleted."
  end

  private

  def load_box
    @box = Box.where(institution: @navigation_context.institution).find(params.fetch(:id))
  end

  def box_params
    params.require(:box).permit(:purpose)
  end

  def new_box_params
    {
      institution: @navigation_context.institution,
      site: @navigation_context.site,
    }
  end
end
