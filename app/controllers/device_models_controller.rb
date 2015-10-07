class DeviceModelsController < ApplicationController

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

    respond_to do |format|
      if @device_model.save
        format.html { redirect_to device_models_path, notice: 'Device Model was successfully created.' }
        format.json { render action: 'show', status: :created, device_model: @device_model }
      else
        format.html { render action: 'new' }
        format.json { render json: @device_model.errors, status: :unprocessable_entity }
      end
    end
  end

  def edit
    @device_model = authorize_resource(DeviceModel.find(params[:id]), UPDATE_DEVICE_MODEL)
  end

  def update
    @device_model = authorize_resource(DeviceModel.find(params[:id]), UPDATE_DEVICE_MODEL) or return

    respond_to do |format|
      if @device_model.update(device_model_update_params)
        format.html { redirect_to device_models_path, notice: 'Device Model was successfully updated.' }
        format.json { render action: 'show', status: :created, device_model: @device_model }
      else
        format.html { render action: 'new' }
        format.json { render json: @device_model.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @device_model = authorize_resource(DeviceModel.find(params[:id]), DELETE_DEVICE_MODEL) or return
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
end
