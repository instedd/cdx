class AlertsController < ApplicationController
  respond_to :html, :json
  
#  set_institution_tab :sites
  
  #TODO [WARNING] You are exposing the `alert` method, which overrides an existing ActionController method of the same name. Consider a different exposure name
  expose(:alerts) { current_user.alerts }
 # expose(:alert, attributes: :alert_params)
  
  #could not name it 'alert' as rails gave a warning as this is a reserved method.
  expose(:alert_info, model: :alert, attributes: :alert_params)

  before_filter do
    head :forbidden unless has_access_to_test_results_index?
  end

  def new
    @sites = check_access(Site.within(@navigation_context.entity), READ_SITE)
    @roles = check_access(Role, READ_ROLE)
    # @devices = check_access(Device, READ_DEVICE).joins(:device_model).includes(:site, :institution, device_model: :institution)
    @devices = check_access(Device, READ_DEVICE)
  
    alert_info.alert_recipients.build 
  end

  def index
    respond_with alerts
  end

  def edit
    @editing = true
    respond_with alert, location: alert_path
  end

  def show
    respond_with alert, location: alert_path
  end


  def create
    #TOADD add site, institution
    #    alert.query =    {"test.error_code"=>"21", "institution.uuid"=>"5227a6f0-17de-ee28-cc66-45c7db5d1bd8", "site.uuid"=>"80bf2237-1a68-0357-2470-58d3706462f9"}

    #TODO assume reactjs will validate errrocode for now
    if alert_info.error_code.include? '-'
      minmax=alert_info.error_code.split('-')
      alert_info.query =    {"test.error_code.min" => minmax[0], "test.error_code.max"=>minmax[1]}
    else
      alert_info.query =    {"test.error_code"=>alert_info.error_code }
    end

    if params[:alert][:site_id]
       alert_info.site = Site.find_by_id(params[:alert][:site_id])  
    end
  
=begin  

    alertRecipients = alert_info.alert_recipients
    alertRecipients.each do |recipient|
   #   user = User.find_by_email(recipient.email)
   #   recipient.user = user
   role = Role.find_by_id(params[:alert][:roles])
   
    end  

=end

=begin
binding.pry
   if params[:alert][:roles]
     role = Role.find_by_id(params[:alert][:roles])
     alertRecipients = alert_info.alert_recipients
     alertRecipients.role = role   
   end
=end


    flash[:notice] = "Alert was successfully created" if alert_info.save

    if params[:alert][:roles]
      roles = params[:alert][:roles].split(',')
      roles.each do |roleid|
        role = Role.find_by_id(roleid)
        alertRecipient = AlertRecipient.new
        alertRecipient.role = role
  #      alertRecipient.user=current_user
        alertRecipient.alert=alert_info
        alertRecipient.save
      end
    end
    
    alert_info.create_percolator     #need to do this for per_record or an aggregation

    respond_with alert_info, location: alerts_path
  end


  def update
    flash[:notice] = "Alert was successfully updated" if alert_info.save
    respond_with alert_info, location: alerts_path
  end

  def destroy
    if alert_info.destroy
      flash[:notice] = "alert was successfully deleted"
      respond_with alert_info
    else
      render :edit
    end
  end

  private

  def alert_params
    params.require(:alert).permit(:name, :description, :error_code, :message, :site_id, :category_type, :aggregation_type, :aggregation_frequency, :channel_type, :sms_limit, :roles, alert_recipients_attributes: [:user, :user_id, :email, :role, :role_id, :id] )
  end
end
