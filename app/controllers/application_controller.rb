class ApplicationController < ActionController::Base
  include ApplicationHelper

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :authenticate_user!
  before_action :load_current_user_policies

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

  def load_current_user_policies
    if current_user
      @current_user_policies = current_user.policies.all
    end
  end

  def authorize_resource(resource, action)
    result = Policy.check_all(action, resource, @current_user_policies, current_user)
    if result.allowed?
      result.resources
    else
      head :forbidden
      nil
    end
  end
end
