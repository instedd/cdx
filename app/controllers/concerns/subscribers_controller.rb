module Concerns::SubscribersController
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
