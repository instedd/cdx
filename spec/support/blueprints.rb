require 'machinist/active_record'
require 'sham'
require 'faker'

class Sham
  # Emulates Machinist 2 serial number
  def self.sn
    @sn ||= 0
    @sn += 1
  end
end

Sham.define do
  name { Faker::Name.name }
  email { Faker::Internet.email }
  password { Faker::Name.name }
end

User.blueprint do
  email
  password
  password_confirmation { password }
  confirmed_at { Time.now - 1.day }
end

Institution.blueprint do
  user
  name
end

Laboratory.blueprint do
  institution
  location
  name
end

Device.blueprint do
  institution
  name
  device_model
  laboratories { [Laboratory.make] }
end

Location.blueprint do
  name
  parent {Location.create_default}
  geo_id { "location-#{Sham.sn}" }
  admin_level {parent.admin_level + 1}
end

DeviceModel.blueprint do
  name
end

Policy.blueprint do
  name
end

Manifest.blueprint do
end

Subscriber.blueprint do
  user
  name
  last_run_at {Time.now}
end

