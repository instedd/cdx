class SubscribersController < ApplicationController
  layout "institutions"
  set_institution_tab :subscribers

  add_breadcrumb 'Institutions', :institutions_path
  before_filter do
    add_breadcrumb institution.name, institution_path(institution)
    add_breadcrumb 'Subscribers', institution_subscribers_path(institution)
  end

  expose(:institution) { current_user.institutions.find(params[:institution_id]) }

  expose(:subscribers) { institution.subscribers }
  expose(:subscriber, attributes: :subscriber_params)

  def show
    add_breadcrumb subscriber.name, institution_subscriber_path(institution, subscriber)
  end

  def edit
    add_breadcrumb subscriber.name, institution_subscriber_path(institution, subscriber)
  end

  def create
    respond_to do |format|
      if subscriber.save
        format.html { redirect_to institution_subscribers_path(institution), notice: 'Subscriber was successfully created.' }
        format.json { render action: 'show', status: :created, location: subscriber }
      else
        format.html { render action: 'new' }
        format.json { render json: subscriber.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if subscriber.update(subscriber_params)
        format.html { redirect_to institution_subscribers_path(institution), notice: 'Subscriber was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: 'edit' }
        format.json { render json: subscriber.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    subscriber.destroy
    respond_to do |format|
      format.html { redirect_to institution_subscribers_url(institution) }
      format.json { head :no_content }
    end
  end

  private

  def subscriber_params
    params.require(:subscriber).permit(:name, :institution_id, :callback_url, :auth_token)
  end
end
