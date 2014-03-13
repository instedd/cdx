class SubscriptionDispatcher
  def initialize(delivery_info, metadata, payload)
    @delivery_info = delivery_info
    @metadata = metadata
    @payload = JSON.parse payload
  end

  def run
    Net::HTTP.get URI.parse("#{@payload['subscriber']['callback_url']}?auth_token=#{@payload['subscriber']['auth_token']}&data=#{@payload['report']['properties'].map {|k, v| "'#{k}':'#{v}'"}.join ','}")
  end
end
