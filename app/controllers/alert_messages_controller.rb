class AlertMessagesController < ApplicationController
  respond_to :html, :json

  before_filter do
    head :forbidden unless has_access_to_test_results_index?
  end

  def index
    @page_size = (params["page_size"] || 10).to_i
    @page = (params["page"] || 1).to_i
    offset = (@page - 1) * @page_size
    
    @alertmessages =  current_user.recipient_notification_history
    @total = @alertmessages.count
    @alertmessages = @alertmessages.limit(@page_size).offset(offset)
    
    respond_with @alertmessages
  end

end
