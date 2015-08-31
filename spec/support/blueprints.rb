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

Device.blueprint do
  laboratory
  institution { laboratory.institution }
  name
  device_model { Manifest.make.device_models.first }
  time_zone { "UTC" }
end

Encounter.blueprint do
  institution
  core_fields { { "id" => "encounter-#{Sham.sn}" } }
end

Sample.blueprint do
  institution
  core_fields { { "uid" => "sample-#{Sham.sn}" } }
end

Patient.blueprint do
  institution
  plain_sensitive_data { {"id" => "patient-#{Sham.sn}" } }
end

TestResult.blueprint do
  device_messages {[DeviceMessage.make]}
  device {device_messages.first.device}
  sample { Sample.make institution: device.institution }
  test_id { "test-#{Sham.sn}" }
end

DeviceMessage.blueprint do
  device
end

DeviceModel.blueprint do
  name
end

Policy.blueprint do
  name
end

Manifest.blueprint do
  definition { DefaultManifest.definition(Faker::Name.name) }
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

Laboratory.blueprint do
  institution
  name
  location_geoid { LocationService.repository.make.id }
  address { Faker::Address.street_address }
  city { Faker::Address.city }
  state { Faker::Address.state }
  zip_code { Faker::Address.zip_code }
  country { Faker::Address.country }
  region { Faker::Address.state }
  lat { rand(-180..180) }
  lng { rand(-90..90) }
end

Location; class Location
  def self.make(params={})
    LocationService.repository.make(params)
  end
end
