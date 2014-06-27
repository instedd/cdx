require 'machinist/active_record'
require 'sham'
require 'faker'

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
end

DeviceModel.blueprint do
  name
end

Policy.blueprint do
  name
end
