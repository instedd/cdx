class DeviceMessagesController < ApplicationController
  before_filter :load_device
  before_filter :load_message, only: [:raw, :reprocess]

  def index
    @messages = @device.device_messages
  end

  def raw
    ext, type = case @device.current_manifest.data_type
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
    redirect_to device_device_messages_path(@device),
                notice: 'The message will be reprocessed'
  end

  private

  def load_device
    @device = Device.find params[:device_id]
    authorize_resource(@device, READ_DEVICE)
  end

  def load_message
    @message = @device.device_messages.find(params[:id])
  end
end
