class Api::FiltersController < ApiController
  respond_to :json

  def index
    respond_with filters
  end

  def show
    render :edit
  end

  private

  def filters
    @filters ||= current_user.filters
  end
end
