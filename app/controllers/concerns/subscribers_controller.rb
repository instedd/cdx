module Concerns::SubscribersController
  extend ActiveSupport::Concern

  included do
    helper_method :filters, :subscribers, :subscriber
  end

  protected

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

  def subscribers
    @subscribers ||=
      if params[:filter_id]
        filters.find(params[:filter_id]).subscribers
      else
        current_user.subscribers
      end
  end

  def subscriber
    @subscriber ||= load_or_initialize_subscriber
  end

  def filters
    @filters ||= current_user.filters
  end

  private

  def load_or_initialize_subscriber
    subscriber =
      if id = params[:id]
        subscribers.find(id)
      else
        subscribers.build
      end

    if params[:subscriber]
      subscriber.attributes = subscriber_params
    end

    subscriber
  end
end
