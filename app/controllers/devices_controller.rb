class DevicesController < ApplicationController
  require 'barby'
  require 'barby/barcode/code_93'
  require 'barby/outputter/html_outputter'
  layout "institutions"
  set_institution_tab :devices

  add_breadcrumb 'Institutions', :institutions_path

  before_filter :load_institution
  before_filter :load_laboratories, only: [:new, :create, :edit, :update]

  before_filter do
    add_breadcrumb @institution.name, institution_path(@institution)
    add_breadcrumb 'Devices', institution_devices_path(@institution)
  end

  def index
    @devices = check_access(@institution.devices, READ_DEVICE)
    @devices ||= []

    @can_create = has_access?(@institution, REGISTER_INSTITUTION_DEVICE)

    @devices_to_edit = check_access(@institution.devices, UPDATE_DEVICE)
    @devices_to_edit ||= []
    @devices_to_edit.map!(&:id)
  end

  def new
    add_breadcrumb 'New'
    @device = @institution.devices.new

    return unless authorize_resource(@institution, REGISTER_INSTITUTION_DEVICE)
  end

  def create
    @device = @institution.devices.new(device_params)
    return unless authorize_resource(@institution, REGISTER_INSTITUTION_DEVICE)

    # TODO: check valid laboratories

    respond_to do |format|
      if @device.save
        format.html { redirect_to institution_devices_path(@institution), notice: 'Device was successfully created.' }
        format.json { render action: 'show', status: :created, location: @device }
      else
        format.html { render action: 'new' }
        format.json { render json: @device.errors, status: :unprocessable_entity }
      end
    end
  end

  def show
    redirect_to edit_institution_device_path(@institution, params[:id])
  end

  def edit
    @device = @institution.devices.find params[:id]
    return unless authorize_resource(@device, UPDATE_DEVICE)

    @uuid_barcode = Barby::Code93.new(@device.uuid)
    @uuid_barcode_for_html = Barby::HtmlOutputter.new(@uuid_barcode)
    # TODO: check valid laboratories

    @can_regenerate_key = has_access?(@device, REGENERATE_DEVICE_KEY)
    @can_generate_activation_token = has_access?(@device, GENERATE_ACTIVATION_TOKEN)
    @can_delete = has_access?(@device, DELETE_DEVICE)

    add_breadcrumb @device.name, institution_device_path(@institution, @device)
  end

  def update
    @device = @institution.devices.find params[:id]
    return unless authorize_resource(@device, UPDATE_DEVICE)

    respond_to do |format|
      if @device.update(device_params)
        format.html { redirect_to institution_devices_path(@institution), notice: 'Device was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @device.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @device = @institution.devices.find params[:id]
    return unless authorize_resource(@device, DELETE_DEVICE)

    @device.destroy

    respond_to do |format|
      format.html { redirect_to institution_devices_url(@institution) }
      format.json { head :no_content }
    end
  end

  def regenerate_key
    @device = @institution.devices.find params[:id]
    return unless authorize_resource(@device, REGENERATE_DEVICE_KEY)
    add_breadcrumb @device.name, edit_institution_device_path(@institution, @device)
    add_breadcrumb 'Secret Key'

    @device.set_key

    @key_barcode = Barby::Code93.new(@device.plain_secret_key)
    @key_barcode_for_html = Barby::HtmlOutputter.new(@key_barcode)

    respond_to do |format|
      if @device.save
        format.html
        format.json { render json: {secret_key: @device.plain_secret_key }.to_json}
      else
        format.html { render action: 'edit' }
        format.json { render json: @device.errors, status: :unprocessable_entity }
      end
    end
  end

  def generate_activation_token
    @device = @institution.devices.find params[:id]
    return unless authorize_resource(@device, GENERATE_ACTIVATION_TOKEN)
    add_breadcrumb @device.name, edit_institution_device_path(@institution, @device)
    add_breadcrumb 'Activation Token'

    @token = @device.new_activation_token
    respond_to do |format|
      if @token.save
        format.html {
          render 'devices/token'
        }
        format.json { render action: 'show', location: @device }
      else
        format.html { render action: 'edit', notice: "Could not generate activation token. #{@token.errors.first}"}
        format.json { render json: @token.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def load_institution
    @institution = Institution.find params[:institution_id]
    authorize_resource(@institution, READ_INSTITUTION)
  end

  def load_laboratories
    @laboratories = check_access(@institution.laboratories, ASSIGN_DEVICE_LABORATORY)
    @laboratories ||= []
  end

  def device_params
    params.require(:device).permit(:name, :device_model_id, :time_zone, laboratory_ids: []).tap do |whitelisted|
      if custom_mappings = params[:device][:custom_mappings]
        whitelisted[:custom_mappings] = custom_mappings.select { |k, v| v.present? }
      end
    end
  end
end
