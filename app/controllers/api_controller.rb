class ApiController < ApplicationController
  include ApplicationHelper
  include Policy::Actions

  skip_before_filter :authenticate_user!
  skip_before_filter :verify_authenticity_token

  before_action :doorkeeper_authorize!, unless: lambda { current_user }

  # We redefine current_user to also take into account the oauth token
  def current_user
    @doorkeeper_user ||= begin
      super || User.find(doorkeeper_token.resource_owner_id)
    end
  end

  def build_csv prefix, builder
    @csv_options = { :col_sep => ',' }
    @csv_builder = builder
    @filename = "#{prefix}-#{DateTime.now.strftime('%Y-%m-%d-%H-%M-%S')}.csv"
  end
end
