class ApiController < ApplicationController
  include ApplicationHelper
  include Policy::Actions

  skip_before_filter :authenticate_user!
  skip_before_filter :verify_authenticity_token
  skip_before_filter :ensure_context

  before_action :doorkeeper_authorize!, unless: lambda { current_user }

  # We redefine current_user to also take into account the oauth token
  def current_user
    unless @doorkeeper_user_cached
      @doorkeeper_user_cached = true
      @doorkeeper_user = super || (doorkeeper_token && User.find(doorkeeper_token.resource_owner_id))
    end
    @doorkeeper_user
  end

  def build_csv prefix, builder
    @csv_options = { :col_sep => ',' }
    @csv_builder = builder
    @filename = "#{prefix}-#{DateTime.now.strftime('%Y-%m-%d-%H-%M-%S')}.csv"
  end
end
