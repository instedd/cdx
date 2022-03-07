class Api::SubscribersController < ApiController
  include Concerns::SubscribersController

  respond_to :json

  def index
    respond_with subscribers
  end

  def show
    respond_with subscriber
  end

  def create
    subscriber.last_run_at = Time.now
    subscriber.save!
    respond_with subscriber
  end

  def update
    subscriber.save!
    respond_with subscriber
  end

  def destroy
    subscriber.destroy
    render json: subscriber
  end
end
