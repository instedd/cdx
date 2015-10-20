class HomeController < ApplicationController
  skip_before_action :authenticate_user!

  def index
  end

  def verify
    render layout: "messages"
  end

  def confirm
    render layout: "clean"
  end

  def join
    render layout: "clean"
  end
end
