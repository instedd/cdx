class Api::FiltersController < ApiController
  expose(:filters) { current_user.filters }

  def index
    render json: filters
  end
end
