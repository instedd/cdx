# Preview all emails at http://localhost:3000/rails/mailers/device_mailer
class DeviceMailerPreview < ActionMailer::Preview
  def setup_instructions
    device = Device.find(2)
    device.set_key
    DeviceMailer.setup_instructions(User.first, "jdoe@example.org", device)
  end
end
