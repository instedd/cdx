class FiltersController < ApplicationController
  def index
    @filters = current_user.filters
  end

  def new
    @filter = Filter.new
    @filter.query = params[:query]
    @laboratory = Laboratory.find(@filter.query[:laboratory])
    @condition = @filter.query[:condition]
  end

  def create
    @filter = current_user.filters.new(filter_params)
    if @filter.save
      redirect_to filters_path, notice: "Filter was successfully created"
    else
      @laboratory = Laboratory.find(@filter.query[:laboratory])
      @condition = @filter.query[:condition]
      render "new"
    end
  end

  def edit
    @filter = current_user.filters.find params[:id]
    @laboratory = Laboratory.find(@filter.query["laboratory"])
    @condition = @filter.query["condition"]
  end

  def update
    @filter = current_user.filters.find params[:id]
    if @filter.update(filter_params)
      redirect_to filters_path, notice: "Filter was successfully updated"
    else
      @laboratory = Laboratory.find @filter.query["laboratory"]
      @condition = @filter.query["condition"]
      render "edit"
    end
  end

  def destroy
    @filter = current_user.filters.find params[:id]
    @filter.destroy
    redirect_to filters_path
  end

  private

  def filter_params
    params.require(:filter).permit(:name).tap do |whitelisted|
      whitelisted[:query] = params[:filter][:query]
    end
  end
end
