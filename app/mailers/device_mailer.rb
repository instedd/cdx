class DeviceMailer < ApplicationMailer
  include BarcodeHelper

  def setup_instructions(sender, receiptment, device)
    @device = device

    if @device.device_model.supports_activation?
      image_barcode(@device.activation_token.value) do |file|
        attachments.inline['activation_token.png'] = file.read
      end
    else
      image_barcode(@device.uuid) do |file|
        attachments.inline['device_id.png'] = file.read
      end
      image_barcode(@device.plain_secret_key) do |file|
        attachments.inline['plain_secret_key.png'] = file.read
      end
    end

    mail(to: receiptment, cc: sender.email, subject: "Setup instructions for #{device.name}")
  end
end
