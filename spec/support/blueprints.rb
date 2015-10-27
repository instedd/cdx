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
  site
  institution { site.institution }
  name
  serial_number { name }
  device_model { Manifest.make.device_model }
  time_zone { "UTC" }
end

DeviceLog.blueprint do
  device
end

DeviceCommand.blueprint do
  device
end

DeviceModel.blueprint do
  name
  published_at { 1.day.ago }
end

DeviceModel.blueprint(:unpublished) do
  name
  published_at { nil }
end

Manifest.blueprint do
  device_model
  definition { DefaultManifest.definition }
end

Encounter.blueprint do
  institution
  core_fields { { "id" => "encounter-#{Sham.sn}" } }
end

SampleIdentifier.blueprint do
  sample
end

Sample.blueprint do
  institution
end

Patient.blueprint do
  institution
  plain_sensitive_data { { "id" => "patient-#{Sham.sn}" } }
end

TestResult.blueprint do
  device_messages { [ DeviceMessage.make ] }
  device { device_messages.first.device }
  sample_identifier { SampleIdentifier.make(sample: Sample.make(institution: device.institution)) }
  test_id { "test-#{Sham.sn}" }
end

DeviceMessage.blueprint do
  device
end

Policy.blueprint do
  name
end

Subscriber.blueprint do
  user
  name
  url
  last_run_at { Time.now }
end

Filter.blueprint do
  user
  name
end

ActivationToken.blueprint do
  device
  value { "token-#{Sham.sn}" }
end

Site.blueprint do
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

Prospect.blueprint do
  first_name { Faker::Name.first_name }
  last_name { Faker::Name.last_name }
  email { Faker::Internet.email }
end

Location; class Location
  def self.make(params={})
    LocationService.repository.make(params)
  end
end
