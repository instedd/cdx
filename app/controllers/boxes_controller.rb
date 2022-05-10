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
    authorize_resource(@box, READ_BOX)
    @can_delete = has_access?(@box, DELETE_BOX)

    @samples = @box.scrambled_samples.preload(:batch).to_a
  end

  def new
    return unless authorize_resource(@navigation_context.institution, CREATE_INSTITUTION_BOX)
    @can_delete = false

    @box = Box.new(new_box_params)
  end

  # def edit
  #   return unless authorize_resource(@box, UPDATE_BOX)
  #   @can_delete = has_access?(@box, DELETE_BOX)
  # end

  def create
    return unless authorize_resource(@navigation_context.institution, CREATE_INSTITUTION_BOX)

    @box = Box.new(new_box_params)
    @box.attributes = box_params

    batch_numbers = params.dig(:box, :batch_numbers).to_a

    case @box.purpose
    when "LOD"
      batch = Batch.find_by!(batch_number: batch_numbers)
      return unless authorize_resource(batch, READ_BATCH)
      @box.build_samples(batch, exponents: 1..8, replicas: 3)

    when "Variants"
      batches = check_access(Batch.where(batch_number: batch_numbers), READ_BATCH)
      batches.each do |batch|
        @box.build_samples(batch, exponents: [1, 4, 8], replicas: 3)
      end

    when "Challenge"
      batch = Batch.find_by!(batch_number: batch_numbers.shift)
      return unless authorize_resource(batch, READ_BATCH)
      @box.build_samples(batch, exponents: [1, 4, 8], replicas: 18)

      batches = check_access(Batch.where(batch_number: batch_numbers), READ_BATCH)
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
