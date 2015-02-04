class SubscribersController < ApplicationController
  def index
    @subscribers = current_user.subscribers
  end

  def new
    @subscriber = Subscriber.new
    @subscriber.fields = []
    @filters = current_user.filters
  end

  def create
    @subscriber = current_user.subscribers.new(subscriber_params)
    @subscriber.last_run_at = Time.now
    @subscriber.fields = (params["fields"] || {}).keys

    if @subscriber.save
      redirect_to subscribers_path, notice: "Subscriber was successfully created"
    else
      @filters = current_user.filters
      render "new"
    end
  end

  def edit
    @subscriber = current_user.subscribers.find params[:id]
    @filters = current_user.filters
  end

  def update
    @subscriber = current_user.subscribers.find params[:id]
    @subscriber.fields = (params["fields"] || {}).keys

    if @subscriber.update(subscriber_params)
      redirect_to subscribers_path, notice: "Subscriber was successfully updated"
    else
      @filters = current_user.filters
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
    params.require(:subscriber).permit(:name, :url, :url_user, :url_password, :filter_id)
  end
end
