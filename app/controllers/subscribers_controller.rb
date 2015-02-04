class SubscribersController < ApplicationController
  def index
    @subscribers = current_user.subscribers
  end

  def new
    @subscriber = Subscriber.new
    @subscriber.fields = []
    @filter_laboratory = params[:laboratory]
    @filter_condition = params[:condition]
    @laboratory = Laboratory.find @filter_laboratory rescue nil
  end

  def create
    @subscriber = current_user.subscribers.new(subscriber_params)
    @subscriber.last_run_at = Time.now
    @subscriber.filter = current_user.filters.create! params: params["filter"], name: "Filter for '#{@subscriber.name}' subscriber"
    @subscriber.fields = (params["fields"] || {}).keys

    if @subscriber.save
      redirect_to subscribers_path, notice: "Subscriber was successfully created"
    else
      @filter_laboratory = @subscriber.filter.query["laboratory"]
      @filter_condition = @subscriber.filter.query["condition"]
      @laboratory = Laboratory.find @filter_laboratory

      render "new"
    end
  end

  def edit
    @subscriber = current_user.subscribers.find params[:id]
    @filter_laboratory = @subscriber.filter.query["laboratory"]
    @filter_condition = @subscriber.filter.query["condition"]
    @laboratory = Laboratory.find @filter_laboratory rescue nil
  end

  def update
    @subscriber = current_user.subscribers.find params[:id]
    @subscriber.filter.query = params["filter"]
    @subscriber.fields = (params["fields"] || {}).keys

    if @subscriber.update(subscriber_params)
      redirect_to subscribers_path, notice: "Subscriber was successfully updated"
    else
      @filter_laboratory = @subscriber.filter.query["laboratory"]
      @filter_condition = @subscriber.filter.query["condition"]
      @laboratory = Laboratory.find @filter_laboratory

      render "edit"
    end
  end

  def destroy
    @subscriber = current_user.subscribers.find params[:id]
    @subscriber.destroy
    redirect_to subscribers_path
  end

  private

  def subscriber_params
    params.require(:subscriber).permit(:name, :url, :url_user, :url_password)
  end
end
