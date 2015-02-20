class FiltersController < ApplicationController
  respond_to :html, :json
  expose(:filters) { current_user.filters }
  expose(:filter, attributes: :filter_params)
  expose(:laboratory) { Laboratory.find(filter.query.with_indifferent_access[:laboratory]) rescue nil }
  expose(:condition) { filter.query.with_indifferent_access[:condition] }

  def index
    respond_with filters
  end

  def show
    respond_with filter
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
    filter.destroy
    respond_with filter
  end

  private

  def filter_params
    params.require(:filter).permit(:name).tap do |whitelisted|
      whitelisted[:query] = params[:filter][:query]
    end
  end
end
