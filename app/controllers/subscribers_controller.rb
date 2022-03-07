class SubscribersController < ApplicationController
  include Concerns::SubscribersController
  skip_before_action :ensure_context

  respond_to :html, :json

  before_filter do
    head :forbidden unless has_access_to_test_results_index?
  end

  def index
    respond_with subscribers
  end

  def show
    respond_with subscriber
  end

  def edit
    @editing = true
  end

  def new
    redirect_to subscribers_path if filters.empty?

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
end
