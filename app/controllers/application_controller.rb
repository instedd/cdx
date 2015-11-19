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
  before_action :ensure_context_in_url
  before_action :load_context

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

  def default_url_options(options={})
    if current_user
      default_context = params[:context] || check_access(Institution, READ_INSTITUTION).first.try(:uuid)
      return {:context => default_context} if default_context
    end

    {}
  end

  def load_context
    @navigation_context = if current_user
      NavigationContext.new(current_user, params[:context])
    else
      NavigationContext.new
    end
  end

  def ensure_context_in_url
    return if request.xhr? || !request.get?
    default_context = default_url_options[:context]
    if params[:context].blank? && default_context
      redirect_to url_for(params)
    end
  end

  protected

  def json_request?
    request.format.json?
  end
end
