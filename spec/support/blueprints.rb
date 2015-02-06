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

SampleSshKey = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC4'+
          'hzyCbJQ5RgrZPFz+rTscTuJ5NPuBIKiinXwkA38CE9+N37L8q9kMqxsbDumVFbamYVlS9fsmF1TqRRhobfJfZGpt'+
          'kcthQde83FWHQGaEQn8T4SG055N5SWNRjQTfMaK0uTTQ28BN44dhLluF/zp4UDHOKRVBrJY4SZq1M5ytkMc6mlZW'+
          'bCAzqtIUUJOMKz4lHn5Os/d8temlYskaKQ1n+FuX5qJXNr1SW8euH72fjQndu78DCwVNwnnrG+nEe3a9m2QwL5xn'+
          'X8f1ohAZ9IG41hwIOvB5UcrFenqYIpMPBCCOnizUcyIFJhegJDWh2oWlBo041emGOX3VCRjtGug3 fbulgarelli@Manass-MacBook-2.local'

Sham.define do
  name { Faker::Name.name }
  email { Faker::Internet.email }
  password { Faker::Name.name }
  url { Faker::Internet.url }
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
  url
  last_run_at {Time.now}
end

Filter.blueprint do
  user
  name
end

ActivationToken.blueprint do
  device
  value { "token-#{Sham.sn}" }
end
