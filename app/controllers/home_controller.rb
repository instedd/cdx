class HomeController < ApplicationController
  skip_before_action :authenticate_user!

  layout 'messages', only: :verify

  def index
  end

  def verify
  end
end
