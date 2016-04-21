class Api::FiltersController < ApiController
  respond_to :json
  expose(:filters) { current_user.filters }

  def index
    respond_with filters
  end

  def show
    render :edit
  end
end
