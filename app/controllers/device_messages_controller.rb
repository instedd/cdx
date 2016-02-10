class DeviceMessagesController < ApplicationController
  before_filter :load_message, only: [:raw, :reprocess]

  def index
    device_ids = check_access(Device, SUPPORT_DEVICE).pluck(:id)
    @messages = DeviceMessage.where("device_id IN (?)", device_ids).joins(device: :device_model)
      .where('devices.site_id = device_messages.site_id')
    apply_filters

    @date_options = date_options_for_filter
    @devices = check_access(Device, READ_DEVICE).within(@navigation_context.entity)
    @device_models = DeviceModel.all
  end

  def raw
    ext, type = case @message.device.current_manifest.data_type
    when 'json'
      ['json', 'application/json']
    when 'csv', 'headless_csv'
      ['csv', 'text/csv']
    when 'xml'
      ['xml', 'application/xml']
    else
      ['txt', 'text/plain']
    end

    send_data @message.plain_text_data, filename: "message_#{@message.id}.#{ext}", type: type
  end

  def reprocess
    @message.reprocess
    redirect_to device_messages_path,
                notice: 'The message will be reprocessed'
  end

  private

  def apply_filters
    @messages = @messages.where("devices.uuid = ?", params["device.uuid"]) if params["device.uuid"].present?
    @messages = @messages.where("device_models.id = ?", params["device_model"]) if params["device_model"].present?
    @messages = @messages.where("index_failure_reason LIKE ?", "%#{params["message"]}%") if params["message"].present?
    @messages = @messages.where("device_messages.created_at > ?", params["created_at"]) if params["created_at"].present?

    @total = @messages.count
    @page_size = (params["page_size"] || 10).to_i
    @page = (params["page"] || 1).to_i
    offset = (@page - 1) * @page_size
    @messages = @messages.limit(@page_size).offset(offset)
  end

  def load_message
    @message = DeviceMessage.find(params[:id])
  end
end
