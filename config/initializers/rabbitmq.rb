class Rabbitmq
  attr_reader :connection, :channel, :queue, :exchange

  def initialize
    @connection = Bunny.new
    @connection.start

    @channel = @connection.create_channel
    @queue  = @channel.queue("cdp_subscribers_exchange", :auto_delete => true)
    @exchange  = @channel.default_exchange

    @queue.subscribe do |delivery_info, metadata, payload|
      SubscriptionDispatcher.new(delivery_info, metadata, payload).run
    end
  end

  def enqueue(content = {})
    @exchange.publish(content.to_json, :routing_key => @queue.name)
  end

  class << self
    def active_connection
      @active_connection ||= new
    end
  end
end

# if defined?(PhusionPassenger) # otherwise it breaks rake commands if you put this in an initializer
#   PhusionPassenger.on_event(:starting_worker_process) do |forked|
#     if forked
#        # We’re in a smart spawning mode
#        # Now is a good time to connect to RabbitMQ
#        $rabbitmq_connection = Bunny.new; $rabbitmq_connection.start
#        $rabbitmq_channel    = @connection.create_channel
#     end
#   end
# end
