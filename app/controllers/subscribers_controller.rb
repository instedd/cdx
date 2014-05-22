class SubscribersController < ApplicationController
  def create
    subscriber = current_user.subscribers.new(subscriber_params)
    subscriber.last_run_at = Time.now
    subscriber.filter = params["filter"].to_json
    subscriber.fields = (params["fields"] || {}).keys.to_json

    if subscriber.save
      redirect_to test_results_path(params["filter"]), notice: "Subscriber created successfully"
    else
      redirect_to test_results_path(params["filter"]), alert: "Couldn't create subscriber"
    end
  end

  private

  def subscriber_params
    params.require(:subscriber).permit(:name, :url, :url_user, :url_password)
  end
end
