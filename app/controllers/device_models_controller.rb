class DeviceModelsController < ApplicationController

  include DeviceModelsHelper

  before_filter :load_institutions

  before_filter do
    @main_column_width = 6 unless params[:action] == 'index'
  end

  def index
    return head :forbidden unless can_index_device_models?

    @device_models = authorize_resource(DeviceModel, READ_DEVICE_MODEL) or return
    @device_models = @device_models.includes(:manifest).includes(:institution)
  end

  def show
    @device_model = authorize_resource(DeviceModel.find(params[:id]), READ_DEVICE_MODEL) or return
    @manifest = @device_model.current_manifest
  end

  def new
    authorize_resource(Institution, REGISTER_INSTITUTION_DEVICE_MODEL) or return

    @device_model = DeviceModel.new
    @device_model.manifest = Manifest.new
    @device_model.institution = @institutions.first if @institutions.one?
  end

  def create
    authorize_resource(Institution.find(device_model_create_params[:institution_id]), REGISTER_INSTITUTION_DEVICE_MODEL) or return
    @device_model = DeviceModel.new(device_model_create_params)
    set_published_status(@device_model)

    respond_to do |format|
      if @device_model.save
        format.html { redirect_to device_models_path, notice: 'Device Model was successfully created.' }
        format.json { render action: 'show', status: :created, device_model: @device_model }
      else
        @device_model.published_at = @device_model.published_at_was
        format.html { render action: 'new' }
        format.json { render json: @device_model.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    @device_model = authorize_resource(DeviceModel.find(params[:id]), UPDATE_DEVICE_MODEL)
  end

  def update
    @device_model = (authorize_resource(DeviceModel.find(params[:id]), UPDATE_DEVICE_MODEL) or return)
    @device_model = (authorize_resource(@device_model, PUBLISH_DEVICE_MODEL) or return) if @device_model.published?

    set_published_status(@device_model)

    respond_to do |format|
      if @device_model.update(device_model_update_params)
        format.html { redirect_to device_models_path, notice: 'Device Model #{@device_model.name} was successfully updated.' }
        format.json { render action: 'show', status: :created, device_model: @device_model }
      else
        @device_model.published_at = @device_model.published_at_was
        format.html { render action: 'new' }
        format.json { render json: @device_model.errors, status: :unprocessable_entity }
      end
    end
  end

  def publish
    @device_model = authorize_resource(DeviceModel.find(params[:id]), PUBLISH_DEVICE_MODEL) or return
    set_published_status(@device_model)
    @device_model.save!

    respond_to do |format|
      format.html { redirect_to device_models_path, notice: "Device Model #{@device_model.name} was successfully #{params[:publish] ? 'published' : 'withdrawn'}." }
      format.json { render action: 'show', status: :created, device_model: @device_model }
    end
  end

  def destroy
    @device_model = DeviceModel.unpublished.find(params[:id])
    @device_model = authorize_resource(@device_model, DELETE_DEVICE_MODEL) or return
    @device_model.destroy!

    respond_to do |format|
      format.html { redirect_to device_models_path }
      format.json { head :no_content }
    end
  end

  private

  def load_institutions
    @institutions = authorize_resource(Institution, REGISTER_INSTITUTION_DEVICE_MODEL)
  end

  def device_model_create_params
    params.require(:device_model).permit(:name, :institution_id, manifest_attributes: [:definition])
  end

  def device_model_update_params
    params.require(:device_model).permit(:name, manifest_attributes: [:definition])
  end

  def set_published_status(device_model)
    device_model.set_published_at   if params[:publish]   && can_publish_device_model?(device_model)
    device_model.unset_published_at if params[:unpublish] && can_unpublish_device_model?(device_model)
  end

end
