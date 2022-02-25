class ApplicationController < ActionController::Base
  include ApplicationHelper

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  skip_before_filter :verify_authenticity_token, if: :json_request?

  before_action :authenticate_user!
  before_action :check_no_institution!
  before_action :load_js_global_settings
  before_action :ensure_context
  before_action :set_locale

  def set_locale
    I18n.locale = current_user.try(:locale) || I18n.default_locale
    @localization_helper = LocalizationHelper.new(current_user.try(:time_zone), I18n.locale,
      current_user.try(:timestamps_in_device_time_zone))
  end

  decent_configuration do
    strategy DecentExposure::StrongParametersStrategy
  end

  def render_json(object, params={})
    render params.merge(text: object.to_json_oj, content_type: 'text/json')
  end

  def self.set_institution_tab(key)
    before_filter do
      send :set_institution_tab, key
    end
  end

  def set_institution_tab(key)
    @institution_tab = key
  end

  def load_js_global_settings
    gon.location_service_url = Settings.location_service_url
    gon.location_service_set = Settings.location_service_set
    gon.location_geocoder = Settings.location_geocoder
    gon.location_default = Settings.location_default
  end

  def authorize_resource(resource, action)
    if has_access?(resource, action)
      check_access(resource, action)
    else
      log_authorization_warn resource, action
      head :forbidden
      nil
    end
  end

  #TODO: refactor authorize_resource and authorize_resource? as both share almost the same code
  def authorize_resource?(resource, action)
    if has_access?(resource, action)
      check_access(resource, action)
    else
      false
    end
  end

  def authorize_resources(resources, action)
    resources.all? { | resource | authorize_resource(resource, action) }
  end

  def check_no_institution!
    return if current_user && current_user.need_change_password?

    if current_user && Institution.all.empty? && has_access?(Institution, CREATE_INSTITUTION)
      redirect_to new_institution_path
      return
    end

    if current_user && current_user.institutions.empty? && current_user.policies.empty? && current_user.roles.empty?
      if has_access?(Institution, CREATE_INSTITUTION)
        pending_institution_invite_id = session[:pending_invite_id] || pending_institution_invite_id_from_url()
        pending_invite = PendingInstitutionInvite.find(pending_institution_invite_id) if pending_institution_invite_id
        if pending_invite and pending_invite.is_pending?
          redirect_to new_from_invite_data_institutions_path(pending_institution_invite_id: pending_institution_invite_id)
          return
        else
          redirect_to new_institution_path
        end
      else
        redirect_to pending_approval_institutions_path
      end
    end
  end

  # filters/authorize navigation_context institutions by action. Assign calls resource.institution= if action is allowed
  def prepare_for_institution_and_authorize(resource, action)
    if authorize_resource(@navigation_context.institution, action).blank?
      log_authorization_warn resource, action
      head :forbidden
      nil
    else
      resource.institution = @navigation_context.institution
    end
  end

  def default_url_options(options={})
    if params[:context].present?
      return {:context => params[:context]}
    end

    {}
  end

  def ensure_context
    return if current_user.nil?

    if params[:context].blank? && !request.xhr?
      # if there is no context information force it to be explicit
      # this will trigger a redirect ?context=<institution_or_site_uuid>

      # grab last context stored in user
      default_context = current_user.last_navigation_context

      # if user has no longer access, reset it to anything that make sense
      if default_context.nil? || !NavigationContext.new(current_user, default_context).can_read?
        some_institution_uuid = check_access(Institution, READ_INSTITUTION).first.try(:uuid)
        current_user.update_attribute(:last_navigation_context, some_institution_uuid)
        default_context = some_institution_uuid
      end

      if default_context
        redirect_to url_for(params.merge({context: default_context}))
      end
    elsif !params[:context].blank?
      # if there is an explicit context try to use it.
      @navigation_context = NavigationContext.new(current_user, params[:context])

      if @navigation_context.can_read?
        # store the navigation context as the last one used
        current_user.update_attribute(:last_navigation_context, params[:context])
      elsif request.xhr?
        # if the user has no longer access to this context, reset it for this request
        @navigation_context = nil
      else
        # or redirect the user to an empty context so a new one is set
        redirect_to url_for(params.merge({context: nil}))
      end
    end
  end

  def after_sign_in_path_for(resource_or_scope)
    pending_invite_id = pending_institution_invite_id_from_url
    if session[:user_return_to] == new_from_invite_data_institutions_path(pending_institution_invite_id: pending_invite_id) and has_access_to_institutions_create?
      new_from_invite_data_institutions_path(pending_institution_invite_id: pending_invite_id)
    elsif has_access?(TestResult, Policy::Actions::MEDICAL_DASHBOARD)
      dashboard_path
    elsif has_access_to_sites_index?
      sites_path
    elsif has_access_to_devices_index?
      devices_path
    elsif has_access_to_device_models_index?
      device_models_path
    elsif has_access_to_test_results_index?
      test_results_path
    elsif can_delegate_permissions?
      policies_path
    elsif has_access_to_patients_index?
      patients_path
    elsif has_access_to_users_index?
      users_path
    elsif has_access?(Device, Policy::Actions::SUPPORT_DEVICE)
      device_messages_path
    elsif has_access_to_settings?
      settings_path
    else
      no_data_allowed_institutions_path
    end
  end

  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path
  end

  def date_options_for_filter
    [{label: "Previous month", value: 1.month.ago.beginning_of_month}, {label: "Previous week", value: 1.week.ago.beginning_of_week},{label: "Previous year", value: 1.year.ago.beginning_of_year}]
  end

  def nndd
    render text: "NNDD"
  end if Rails.env.test?

  protected

  def json_request?
    request.format.json?
  end

  def perform_pagination(rel)
    @page_size = (params["page_size"] || 10).to_i
    @page = (params["page"] || 1).to_i
    rel = rel.page(@page).per(@page_size)
    @total = rel.total_count
    rel
  end

  def log_authorization_warn(resource, action)
    resource_name =
      if resource.is_a? Class
        "#{resource} class"
      else
        "#{resource.class} (id=#{resource.id})"
      end
    logger.warn "Authorization failed. #{action} requested by #{current_user.email} in #{resource_name}"
  end

  private

  def pending_institution_invite_id_from_url
    url = session[:user_return_to] || request.original_url
    parsed_url = URI.parse(url)
    parsed_query = URI::decode_www_form(parsed_url.query).to_h unless parsed_url.query.nil?
    if parsed_query and parsed_query.has_key?("pending_institution_invite_id")
      session[:pending_invite_id] = parsed_query["pending_institution_invite_id"]
      parsed_query["pending_institution_invite_id"]
    end
  end

end
