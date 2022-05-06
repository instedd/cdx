class BoxesController < ApplicationController
  before_action :load_box, except: %i[index new create]

  def index
    @can_create = has_access?(@navigation_context.institution, CREATE_INSTITUTION_BOX)

    @boxes = Box.where(institution: @navigation_context.institution)
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
    @can_update = false # has_access?(@box, UPDATE_BOX)
    @can_delete = has_access?(@box, DELETE_BOX)
  end

  def create
    return unless authorize_resource(@navigation_context.institution, CREATE_INSTITUTION_BOX)

    @box = Box.new(new_box_params)
    @box.attributes = box_params

    if @box.save
      redirect_to boxes_path, notice: "Box was successfully created."
    else
      render :new
    end
  end

  def update
    return unless authorize_resource(@box, UPDATE_BOX)

    if @box.update(box_params)
      redirect_to boxes_path, notice: "Box was successfully updated."
    else
      render :edit
    end
  end

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
