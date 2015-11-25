class DeviceMailer < ApplicationMailer
  include BarcodeHelper

  def setup_instructions(sender, receiptment, device)
    @device = device

    if !@device.device_model.supports_activation?
      image_barcode(@device.uuid) do |file|
        attachments.inline['device_id.png'] = file.read
      end
    end

    mail(to: receiptment, cc: sender.email, subject: "Setup instructions for #{device.name}")
  end
end
