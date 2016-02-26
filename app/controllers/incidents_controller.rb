class IncidentsController < ApplicationController
  respond_to :html, :json

  before_filter do
    head :forbidden unless has_access_to_test_results_index?
  end

  def index
    @page_size = (params["page_size"] || 10).to_i
    @page = (params["page"] || 1).to_i
    offset = (@page - 1) * @page_size

    @date_options = date_options_for_filter

    @devices = check_access(Device.within(@navigation_context.entity), READ_DEVICE)
    @alerts = Alert.where({user_id: current_user.id})

    @incidents =  current_user.alert_histories.where({for_aggregation_calculation: false}).joins(:alert)

    if ( !params["alert.id"].blank? )
      @incidents = @incidents.where("alerts.id=?",params["alert.id"].to_i)
    end

    if ( !params["device.uuid"].blank? )
=begin
      add this code to the incident filter

      .filter
      %label.block Device
      = cdx_select name: "device.uuid", value: params["device.uuid"] do |select|
        - select.item "", "Show all"
        - select.items @devices, :uuid, :name

=end
        #works:  Alert.joins(:devices).where("devices.uuid=?","dd").count
        @incidents = @incidents.where("alerts.device.uuid=?",params["device.uuid"])
      end

      if ( !params["since"].blank? )
        @incidents = @incidents.where("alert_histories.created_at > ?", params["since"] )
      end

      if ( !params["sample.id"].blank? )
        @incidents = @incidents.where("alerts.sample_id = ?", params["sample.id"] )
      end

      @total = @incidents.count
      @incidents = @incidents.limit(@page_size).offset(offset)

      respond_with @incidents
    end
  end
