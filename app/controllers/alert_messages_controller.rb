class AlertMessagesController < ApplicationController
  respond_to :html, :json
  expose(:alertmessages) { current_user.recipient_notification_history }

  before_filter do
    head :forbidden unless has_access_to_test_results_index?
  end

  def index
    respond_with alertmessages
  end

  def show
    #    render :edit
  end

end
