class HomeController < ApplicationController
  skip_before_action :authenticate_user!

  def index
  end

  def verify
    render layout: "messages"
  end

  def join
    render layout: "clean"
  end

  def design
  end
end
