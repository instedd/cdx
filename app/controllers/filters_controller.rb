class FiltersController < ApplicationController
  # TODO should split API controller
  skip_before_action :authenticate_user!, if: -> { request.path.starts_with? "/api/" }
  before_filter :authenticate_api_user!, if: -> { request.path.starts_with? "/api/" }

  respond_to :html, :json
  expose(:filters) { current_user.filters }
  expose(:filter, attributes: :filter_params)
  expose(:laboratory) { Laboratory.find(filter.query["laboratory.id"]) rescue nil }
  expose(:condition) { filter.query["test.assays.condition"] }

  def index
    respond_with filters
  end

  def show
    render :edit
  end

  def new
    filter.query = params[:query]
  end

  def create
    flash[:notice] = "Filter was successfully created" if filter.save
    respond_with filter, location: filters_path
  end

  def update
    flash[:notice] = "Filter was successfully updated" if filter.save
    respond_with filter, location: filters_path
  end

  def destroy
    if filter.destroy
      flash[:notice] = "Filter was successfully deleted"
      respond_with filter
    else
      render :edit
    end
  end

  private

  def filter_params
    params.require(:filter).permit(:name).tap do |whitelisted|
      whitelisted[:query] = params[:filter][:query]
    end
  end
end
