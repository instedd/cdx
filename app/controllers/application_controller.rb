class ApplicationController < ActionController::Base
  include ApplicationHelper
  include Policy::Actions

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  skip_before_filter :verify_authenticity_token, if: :json_request?

  before_action :authenticate_user!
  before_action :check_no_institution!
  before_action :load_js_global_settings

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
  end

  def authorize_resource(resource, action)
    if Policy.can?(action, resource, current_user)
      Policy.authorize(action, resource, current_user)
    else
      head :forbidden
      nil
    end
  end

  def check_no_institution!
    return if current_user && current_user.need_change_password?
    if current_user && current_user.institutions.empty? && current_user.policies.empty?
      if has_access?(Institution, CREATE_INSTITUTION)
        redirect_to new_institution_path
      else
        redirect_to pending_approval_institutions_path
      end
    end
  end

  # filters/authorize @institutions by action. Assign calls resource.institution= if only one institution was left
  def prepare_for_institution_and_authorize(resource, action)
    @institutions = authorize_resource(@institutions, action)
    if @institutions.blank?
      head :forbidden
      nil
    elsif @institutions.one?
      resource.institution = @institutions.first
      @institutions
    else
      @institutions
    end
  end

  def after_sign_in_path_for(resource_or_scope)
    if has_access?(TestResult, Policy::Actions::MEDICAL_DASHBOARD)
      nndd_path
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
    end
  end

  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path
  end

  def nndd
    render text: "NNDD"
  end if Rails.env.test?

  protected

  def json_request?
    request.format.json?
  end
end
