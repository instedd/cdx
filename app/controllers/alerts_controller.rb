class AlertsController < ApplicationController
  respond_to :html, :json

  expose(:alerts) { current_user.alerts }

  #could not name it 'alert' as rails gave a warning as this is a reserved method.
  expose(:alert_info, model: :alert, attributes: :alert_params)

  before_filter do
    head :forbidden unless has_access_to_test_results_index?
  end

  def new
    new_alert_request_variables
    alert_info.alert_recipients.build
  end

  def index
    @page_size = (params["page_size"] || 10).to_i
    @page = (params["page"] || 1).to_i
    offset = (@page - 1) * @page_size
    respond_with alerts
  end

  def edit
    new_alert_request_variables

    @alert_devices=[]
    alert_info.devices.each do |device|
      @alert_devices.push(device.id)
    end
    @alert_devices = @alert_devices.join(",")

    @alert_roles=[]
    alert_info.alert_recipients.each do |recipient|
      if AlertRecipient.recipient_types[recipient.recipient_type] == AlertRecipient.recipient_types["role"]
        @alert_roles.push(recipient.role.id)
      end
    end
    @alert_roles = @alert_roles.join(",")

    @alert_internal_users=[]
    alert_info.alert_recipients.each do |recipient|
      if AlertRecipient.recipient_types[recipient.recipient_type] == AlertRecipient.recipient_types["internal_user"]
        @alert_internal_users.push(recipient.user.id)
      end
    end
    @alert_internal_users = @alert_internal_users.join(",")


    @alert_external_users=[]
    alert_info.alert_recipients.each do |recipient|
      if AlertRecipient.recipient_types[recipient.recipient_type] == AlertRecipient.recipient_types["external_user"]
        @alert_external_users.push(recipient)
      end
    end

    respond_with alert_info, location: alert_path
  end


  def show
    respond_with alert_info, location: alert_path
  end


  def create
    external_users_ok = true
    error_text=Hash.new

    alert_saved_ok = alert_info.save

    if alert_saved_ok==false
      error_text = alert_info.errors.messages
    else
      alert_saved_ok

      if params[:alert][:roles]
        roles = params[:alert][:roles].split(',')
        roles.each do |role_id|
          role = Role.find_by_id(role_id)
          alertRecipient = AlertRecipient.new
          alertRecipient.recipient_type = AlertRecipient.recipient_types["role"]
          alertRecipient.role = role
          alertRecipient.alert=alert_info
          alertRecipient.save
        end
      end

      #save internal users
      if params[:alert][:users_info]
        internal_users = params[:alert][:users_info].split(',')
        internal_users.each do |user_id|

          user = User.find_by_id(user_id)
          alertRecipient = AlertRecipient.new
          alertRecipient.recipient_type = AlertRecipient.recipient_types["internal_user"]
          alertRecipient.user = user
          alertRecipient.alert=alert_info
          alertRecipient.save
        end
      end

      #save external users
      if params[:alert][:external_users]
        external_users = params[:alert][:external_users]

        # using key/pair as value returned in this format  :
        #  {"0"=>{"id"=>"0", "firstName"=>"a", "lastName"=>"b", "email"=>"c", "telephone"=>"d"}, "1"=>{"id"=>"1", "firstName"=>"aa", "lastName"=>"bb", "email"=>"cc", "telephone"=>"dd"}}
        external_users.each do |key, external_user_value|
          alertRecipient = AlertRecipient.new
          alertRecipient.recipient_type = AlertRecipient.recipient_types["external_user"]
          alertRecipient.email = external_user_value["email"]
          alertRecipient.telephone = external_user_value["telephone"]
          alertRecipient.first_name = external_user_value["first_name"]
          alertRecipient.last_name = external_user_value["last_name"]
          alertRecipient.alert=alert_info

          if alertRecipient.save == false
            external_users_ok = false
            error_text = error_text.merge alertRecipient.errors.messages
          end

        end
      end


      alert_info.query="{}";

      if alert_info.category_type == "anomalies"

        # check that the start_time field is not missing
        if alert_info.anomalie_type == "missing_sample_id"
          alert_info.query = {"sample.id"=>"null" }
        elsif alert_info.anomalie_type == "missing_start_time"
          alert_info.query = {"test.start_time"=>"null" }
        end
      end
      if alert_info.category_type == "device_errors"
        if alert_info.error_code && (alert_info.error_code.include? '-')
          minmax=alert_info.error_code.split('-')
          alert_info.query =    {"test.error_code.min" => minmax[0], "test.error_code.max"=>minmax[1]}
          #   alert_info.query=alert_info.query.merge ({"test.error_code.min" => minmax[0], "test.error_code.max"=>minmax[1]})
          #elsif alert_info.error_code.include? '*'
          #   alert_info.query =    {"test.error_code.wildcard" => "*7"}
        else
          alert_info.query =    {"test.error_code"=>alert_info.error_code }
          #   alert_info.query=alert_info.query.merge ({"test.error_code"=>alert_info.error_code });
        end
      end

      if params[:alert][:sites_info]
        sites = params[:alert][:sites_info].split(',')
        query_sites=[]
        sites.each do |siteid|
          site = Site.find_by_id(siteid)
          alert_info.sites << site
          query_sites << site.uuid
        end
        #Note:  the institution uuid should not be necessary
        alert_info.query=alert_info.query.merge ({"site.uuid"=>query_sites})
      end


      #TODO you have the device uuid, you don’t even need the site uuid
      if params[:alert][:devices_info]
        devices = params[:alert][:devices_info].split(',')
        query_devices=[]
        devices.each do |deviceid|
          device = Device.find_by_id(deviceid)
          alert_info.devices << device
          query_devices << device.uuid
        end
        alert_info.query=alert_info.query.merge ({"device.uuid"=>query_devices})
      end

      #Note: alert_info.create_percolator is called from the model
    end

    alert_query_updated_ok = alert_info.update(query: alert_info.query)

    if alert_saved_ok && alert_query_updated_ok && external_users_ok
      render json: alert_info
    else
      render json: error_text, status: :unprocessable_entity
    end
  end


  def update
    #update in model calls create
    if alert_info.enabled == false
      alert_info.delete_percolator
    end

    if alert_info.save
      render json: alert_info
    else
      render json: alert_info.errors, status: :unprocessable_entity
    end

    #  flash[:notice] = "Alert was successfully updated" if alert_info.save
    #  respond_with alert_info, location: alerts_path
  end


  def destroy
    if alert_info.destroy
      render json: alert_info
    else
      render json: alert_info.errors, status: :unprocessable_entity
    end


  end


  private

  def alert_params
    params.require(:alert).permit(:name, :description, :devices_info, :users_info, :enabled, :sites_info, :error_code, :message, :sms_message, :site_id, :category_type, :notify_patients, :aggregation_type, :anomalie_type, :aggregation_frequency, :channel_type, :sms_limit, :roles, :external_users, alert_recipients_attributes: [:user, :user_id, :email, :role, :role_id, :id] )
  end

  def new_alert_request_variables
    @sites = check_access(Site.within(@navigation_context.entity), READ_SITE)
    @roles = check_access(Role, READ_ROLE)
    @devices = check_access(Device, READ_DEVICE)

    #find all users in all roles
    user_ids = @roles.map { |user| user.id }
    user_ids = user_ids.uniq
    @users = User.where(id: user_ids)
  end

end
