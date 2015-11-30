class DeviceModelsController < ApplicationController

  include DeviceModelsHelper

  before_filter do
    head :forbidden unless has_access_to_device_models_index?
  end

  def index
    @device_models = authorize_resource(DeviceModel, READ_DEVICE_MODEL) or return
    @device_models = @device_models.includes(:manifest)
    @device_models = @device_models.where(institution:  @navigation_context.institution)

    @updateable_device_model_ids  = check_access(DeviceModel, UPDATE_DEVICE_MODEL).pluck(:id)
    @publishable_device_model_ids = check_access(DeviceModel, PUBLISH_DEVICE_MODEL).pluck(:id)
  end

  def show
    @device_model = authorize_resource(DeviceModel.find(params[:id]), READ_DEVICE_MODEL) or return
    @manifest = @device_model.current_manifest
  end

  def new
    @device_model = DeviceModel.new
    @device_model.manifest = Manifest.new

    return unless prepare_for_institution_and_authorize(@device_model, REGISTER_INSTITUTION_DEVICE_MODEL)
  end

  def create
    load_manifest_upload
    @device_model = DeviceModel.new(device_model_create_params)
    return unless prepare_for_institution_and_authorize(@device_model, REGISTER_INSTITUTION_DEVICE_MODEL)
    set_published_status(@device_model)

    respond_to do |format|
      if @device_model.save
        format.html { redirect_to device_models_path, notice: 'Device Model was successfully created.' }
        format.json { render action: 'show', status: :created, device_model: @device_model }
      else
        @device_model.published_at = @device_model.published_at_was
        @device_model.setup_instructions = nil
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
    load_manifest_upload

    respond_to do |format|
      if @device_model.update(device_model_update_params)
        format.html { redirect_to device_models_path, notice: "Device Model #{@device_model.name} was successfully updated." }
        format.json { render action: 'show', status: :created, device_model: @device_model }
      else
        @device_model.published_at = @device_model.published_at_was
        @device_model.setup_instructions = DeviceModel.find(params[:id]).setup_instructions
        format.html { render action: 'edit' }
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

  def manifest
    @device_model = authorize_resource(DeviceModel.find(params[:id]), READ_DEVICE_MODEL) or return
    @manifest = @device_model.current_manifest

    send_data @manifest.definition, type: :json, disposition: "attachment", filename: @manifest.filename
  end

  private

  def device_model_create_params
    params.require(:device_model).permit(:name, :picture, :delete_picture, :setup_instructions, :delete_setup_instructions, :institution_id, :supports_activation, :support_url, manifest_attributes: [:definition])
  end

  def device_model_update_params
    params.require(:device_model).permit(:name, :picture, :delete_picture, :setup_instructions, :delete_setup_instructions, :supports_activation, :support_url, manifest_attributes: [:definition])
  end

  def set_published_status(device_model)
    device_model.set_published_at   if params[:publish]   && can_publish_device_model?(device_model)
    device_model.unset_published_at if params[:unpublish] && can_unpublish_device_model?(device_model)
  end

  def load_manifest_upload
    if params[:device_model][:manifest_attributes] && params[:device_model][:manifest_attributes][:definition]
      # this is for testing. specs had String manifest. It should be migrated to temp file and fixture_file_upload
      unless params[:device_model][:manifest_attributes][:definition].is_a?(String)
        params[:device_model][:manifest_attributes][:definition] = params[:device_model][:manifest_attributes][:definition].read
      end
    else
      params[:device_model][:manifest_attributes] ||= {}
      params[:device_model][:manifest_attributes][:definition] = @device_model.try { |dm| dm.current_manifest.definition }
    end
  end

end
