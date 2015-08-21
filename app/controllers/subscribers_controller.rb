class SubscribersController < ApplicationController
  # TODO should split API controller
  skip_before_action :authenticate_user!, if: -> { request.path.starts_with? "/api/" }
  before_filter :authenticate_api_user!, if: -> { request.path.starts_with? "/api/" }

  respond_to :html, :json
  expose(:subscribers) do
    if params[:filter_id]
      current_user.filters.find(params[:filter_id]).subscribers
    else
      current_user.subscribers
    end
  end
  expose(:subscriber, attributes: :subscriber_params)
  expose(:filters) { current_user.filters }

  def index
    respond_with subscribers
  end

  def show
    respond_with subscriber
  end

  def new
    subscriber.fields = []
  end

  def create
    subscriber.last_run_at = Time.now
    flash[:notice] = "Subscriber was successfully created" if subscriber.save
    respond_with subscriber, location: subscribers_path
  end

  def update
    flash[:notice] = "Subscriber was successfully updated" if subscriber.save
    respond_with subscriber, location: subscribers_path
  end

  def destroy
    subscriber.destroy
    respond_with subscriber
  end

  private

  def subscriber_params
    params.require(:subscriber).permit(:name, :url, :verb, :url_user, :url_password, :filter_id).tap do |whitelisted|
      whitelisted[:fields] ||= begin
        case fields = params[:subscriber][:fields] || params[:fields]
        when Array then fields
        when Hash then fields.keys
        else []
        end
      end
    end
  end
end
