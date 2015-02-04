class FiltersController < ApplicationController
  expose(:filters) { current_user.filters }
  expose(:filter, attributes: :filter_params)
  expose(:laboratory) { Laboratory.find(filter.query.with_indifferent_access[:laboratory]) }
  expose(:condition) { filter.query.with_indifferent_access[:condition] }

  def new
    filter.query = params[:query]
  end

  def create
    if filter.save
      redirect_to filters_path, notice: "Filter was successfully created"
    else
      render :new
    end
  end

  def update
    if filter.save
      redirect_to filters_path, notice: "Filter was successfully updated"
    else
      render :edit
    end
  end

  def destroy
    filter.destroy
    redirect_to filters_path
  end

  private

  def filter_params
    params.require(:filter).permit(:name).tap do |whitelisted|
      whitelisted[:query] = params[:filter][:query]
    end
  end
end
