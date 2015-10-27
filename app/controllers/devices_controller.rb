class DevicesController < ApplicationController
  before_filter :load_device, except: [:index, :new, :create, :show, :custom_mappings, :device_models]
  before_filter :load_institutions, only: [:new, :create, :edit, :update, :device_models]
  before_filter :load_sites, only: [:new, :create, :edit, :update]
  before_filter :load_institution, only: :create
  before_filter :load_device_models_for_create, only: [:new, :create]
  before_filter :load_device_models_for_update, only: [:edit, :update]
  before_filter :load_filter_resources, only: :index

  before_filter do
    @main_column_width = 6 unless params[:action] == 'index'
  end

  def index
    return head :forbidden unless has_access_to_devices_index?

    @devices = check_access(Device, READ_DEVICE)

    @devices = @devices.where(institution_id: params[:institution].to_i) if params[:institution].presence
    @devices = @devices.where(site_id:  params[:site].to_i)  if params[:site].presence

    @can_create = has_access?(Institution, REGISTER_INSTITUTION_DEVICE)
    @devices_to_read = check_access(Device, READ_DEVICE).pluck(:id)
  end

  def new
    @device = Device.new
    @device.time_zone = "UTC"
    return unless prepare_for_institution_and_authorize(@device, REGISTER_INSTITUTION_DEVICE)
  end

  def create
    return unless authorize_resource(@institution, REGISTER_INSTITUTION_DEVICE)

    @device = @institution.devices.new(device_params)
    if @device.device_model.supports_activation?
      @device.new_activation_token
    end

    # TODO: check valid sites

    respond_to do |format|
      if @device.save
        format.html { redirect_to setup_device_path(@device), notice: 'Device was successfully created.' }
        format.json { render action: 'show', status: :created, location: @device }
      else
        format.html do
          @institutions = check_access(Institution, REGISTER_INSTITUTION_DEVICE)
          render action: 'new'
        end
        format.json { render json: @device.errors, status: :unprocessable_entity }
      end
    end
  end

  def show
    @device = Device.find(params[:id])
    return unless authorize_resource(@device, READ_DEVICE)
    redirect_to setup_device_path(@device) unless @device.activated?
  end

  def setup
    @device = Device.find(params[:id])
    return unless authorize_resource(@device, UPDATE_DEVICE)

    unless @device.secret_key_hash?
      # This is the first time the setup page is displayed (after create)
      # Create a secret key to be shown to the user
      @device.set_key
      @device.new_activation_token
      @device.save!
    end

    render layout: false if request.xhr?
  end


  def edit
    return unless authorize_resource(@device, UPDATE_DEVICE)

    @uuid_barcode = Barby::Code93.new(@device.uuid)
    @uuid_barcode_for_html = Barby::HtmlOutputter.new(@uuid_barcode)
    # TODO: check valid sites
    @can_regenerate_key = has_access?(@device, REGENERATE_DEVICE_KEY)
    @can_generate_activation_token = has_access?(@device, GENERATE_ACTIVATION_TOKEN)
    @can_delete = has_access?(@device, DELETE_DEVICE)
    @can_support = has_access?(@device, SUPPORT_DEVICE)
  end

  def update
    return unless authorize_resource(@device, UPDATE_DEVICE)

    respond_to do |format|
      if @device.update(device_params)
        format.html { redirect_to devices_path, notice: 'Device was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: @device.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    return unless authorize_resource(@device, DELETE_DEVICE)

    @device.destroy

    respond_to do |format|
      format.html { redirect_to devices_path, notice: 'Device was successfully deleted.' }
      format.json { head :no_content }
    end
  end

  def regenerate_key
    return unless authorize_resource(@device, REGENERATE_DEVICE_KEY)

    @device.set_key

    respond_to do |format|
      if @device.save
        format.js
        format.json { render json: {secret_key: @device.plain_secret_key }.to_json}
      else
        format.js
        format.json { render json: @device.errors, status: :unprocessable_entity }
      end
    end
  end

  def generate_activation_token
    return unless authorize_resource(@device, GENERATE_ACTIVATION_TOKEN)

    @token = @device.new_activation_token
    respond_to do |format|
      if @token.save
        format.js
        format.json { render json: @token }
      else
        format.js
        format.json { render json: @token.errors, status: :unprocessable_entity }
      end
    end
  end

  def request_client_logs
    return unless authorize_resource(@device, SUPPORT_DEVICE)

    @device.request_client_logs

    redirect_to devices_path, notice: "Client logs requested"
  end

  def custom_mappings
    if params[:device_model_id].blank?
      return render html: ""
    end

    if params[:device_id].present?
      @device = Device.find(params[:device_id])
      return unless authorize_resource(@device, UPDATE_DEVICE)
    else
      @device = Device.new
    end

    @device.device_model = DeviceModel.find(params[:device_model_id])

    render partial: 'custom_mappings'
  end

  def device_models
    load_device_models_for_create

    institution_id = params[:institution_id].to_i
    @device_models = @device_models.select { |device_model| device_model.published? || device_model.institution_id == institution_id }.to_a

    render partial: 'device_models'
  end

  def performance
    @device = Device.find(params[:id])
    return unless authorize_resource(@device, READ_DEVICE)
    since = (Date.today - 1.year).iso8601

    @tests_histogram = query_tests_histogram
    @tests_by_name = query_tests_by_name
    @errors_histogram, @error_users = query_errors_histogram
    @errors_by_code = query_errors_by_code

    render layout: false if request.xhr?
  end

  def tests
    render layout: false
  end

  def logs
    render layout: false
  end

  private

  def load_institution
    @institution = Institution.find params[:device][:institution_id]
    authorize_resource(@institution, READ_INSTITUTION)
  end

  def load_institutions
    @institutions = check_access(Institution, REGISTER_INSTITUTION_DEVICE)
  end

  def load_sites
    @sites = check_access(Site, ASSIGN_DEVICE_SITE)
    @sites ||= []
  end

  def load_filter_resources
    @institutions, @sites = Policy.condition_resources_for(READ_DEVICE, Device, current_user).values
  end

  def load_device
    @device = Device.find(params[:id])
  end

  def load_device_models_for_create
    gon.device_models = @device_models = \
      (DeviceModel.includes(:institution).published.to_a + \
       DeviceModel.includes(:institution).unpublished.where(institution_id: @institutions.map(&:id)).to_a)
  end

  def load_device_models_for_update
    @device_models = \
      (DeviceModel.includes(:institution).published.to_a + \
       DeviceModel.includes(:institution).unpublished.where(institution_id: @device.institution_id).to_a)
  end

  def device_params
    params.require(:device).permit(:name, :serial_number, :device_model_id, :time_zone, :site_id).tap do |whitelisted|
      if custom_mappings = params[:device][:custom_mappings]
        whitelisted[:custom_mappings] = custom_mappings.select { |k, v| v.present? }
      end
    end
  end

  def query_tests_histogram
    query = {
      "group_by" => "month(test.reported_time)",
      "since" => (Date.today - 1.year).iso8601
    }
    result = TestResult.query(query, current_user).execute
    result = Hash[result["tests"].map { |i| [i["test.reported_time"], i["count"]] }]

    tests_histogram = []
    11.downto(0).each do |i|
      date = Date.today - i.months
      date_key = date.strftime("%Y-%m")
      tests_histogram << {
        label: "#{I18n.t("date.abbr_month_names")[date.month]}#{date.month == 1 ? " #{date.strftime("%y")}" : ""}",
        values: [result[date_key] || 0]
      }
    end
    tests_histogram
  end

  def query_errors_histogram
    query = {
      "test.status" => "error",
      "group_by" => "month(test.reported_time),test.site_user",
      "since" => (Date.today - 1.year).iso8601
    }
    result = TestResult.query(query, current_user).execute
    users = result["tests"].index_by { |t| t["test.site_user"] }.keys
    results_by_day = result["tests"].group_by { |t| t["test.reported_time"] }

    errors_histogram = []
    11.downto(0).each do |i|
      date = Date.today - i.months
      date_key = date.strftime("%Y-%m")
      date_results = results_by_day[date_key].try { |r| r.index_by { |t| t["test.site_user"] } }
      errors_histogram << {
        label: "#{I18n.t("date.abbr_month_names")[date.month]}#{date.month == 1 ? " #{date.strftime("%y")}" : ""}",
        values: users.map do |u|
          user_result = date_results && date_results[u]
          user_result ? user_result["count"] : 0
        end
      }
    end
    return errors_histogram, users
  end

  def query_errors_by_code
    query = {
      "test.status" => "error",
      "since" => (Date.today - 1.year).iso8601,
    }
    total_count = TestResult.query(query, current_user).execute["total_count"]
    no_error_code = total_count

    query = {
      "test.status" => "error",
      "group_by" => "test.error_code",
      "since" => (Date.today - 1.year).iso8601
    }
    result = TestResult.query(query, current_user).execute
    pie_data = result["tests"].map do |test|
      no_error_code -= test["count"]

      {
        label: test["test.error_code"],
        value: test["count"]
      }
    end

    pie_data << {label: 'Unknown', value: no_error_code} if no_error_code > 0

    pie_data
  end

  def query_tests_by_name
    query = {
      "group_by" => "test.name",
      "since" => (Date.today - 1.year).iso8601
    }
    result = TestResult.query(query, current_user).execute
    result["tests"].map do |test|
      {
        label: test["test.name"],
        value: test["count"]
      }
    end
  end
end
