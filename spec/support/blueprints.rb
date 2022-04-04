require 'machinist/active_record'
require 'ffaker'
require_relative "../policy_spec_helper"

SampleSshKey = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC4'+
          'hzyCbJQ5RgrZPFz+rTscTuJ5NPuBIKiinXwkA38CE9+N37L8q9kMqxsbDumVFbamYVlS9fsmF1TqRRhobfJfZGpt'+
          'kcthQde83FWHQGaEQn8T4SG055N5SWNRjQTfMaK0uTTQ28BN44dhLluF/zp4UDHOKRVBrJY4SZq1M5ytkMc6mlZW'+
          'bCAzqtIUUJOMKz4lHn5Os/d8temlYskaKQ1n+FuX5qJXNr1SW8euH72fjQndu78DCwVNwnnrG+nEe3a9m2QwL5xn'+
          'X8f1ohAZ9IG41hwIOvB5UcrFenqYIpMPBCCOnizUcyIFJhegJDWh2oWlBo041emGOX3VCRjtGug3 fbulgarelli@Manass-MacBook-2.local'

User.blueprint do
  email { FFaker::Internet.email }
  password { FFaker::Internet.password }
  first_name { FFaker::Name.first_name }
  last_name { FFaker::Name.last_name }
  password_confirmation { password }
  confirmed_at { 1.day.ago }
end

Alert.blueprint do
  name { FFaker::Name.first_name }
  description { FFaker::Name.last_name }
  message { 'test message' }
  category_type {"anomalies"}
  sms_limit {10000}
  user
end

AlertRecipient.blueprint do
  user
  alert
  recipient_type {AlertRecipient.recipient_types["external_user"]}
  email {"aaa@aaa.com"}
  telephone {123}
  first_name {"bob"}
  last_name {'smith'}
end


User.blueprint(:invited_pending) do
  confirmed_at { nil }
  invitation_token { SecureRandom.urlsafe_base64 }
  invitation_created_at { 1.day.ago }
  invitation_sent_at { 1.day.ago }
  invitation_accepted_at { nil }
  object.__send__(:generate_invitation_token)
end

Institution.blueprint do
  user
  name { FFaker::Name.name }
end

Institution.blueprint(:manufacturer) do
  kind { "manufacturer" }
end

PendingInstitutionInvite.blueprint do
  invited_user_email { Faker::Internet.email }
  invited_by_user { User.make }
  institution_name { Faker::Name.name }
  institution_kind { "institution" }
  status { "pending" }
end

Device.blueprint do
  site { Site.make(institution: (object.institution || Institution.make)) }
  institution { object.site.try(:institution) || Institution.make }
  name { FFaker::Name.name }
  serial_number { sn }
  device_model { Manifest.make!.device_model }
  time_zone { "UTC" }
end

DeviceLog.blueprint do
  device
end

DeviceCommand.blueprint do
  device
end

DeviceModel.blueprint do
  name { FFaker::Name.name }
  published_at { 1.day.ago }
end

DeviceModel.blueprint(:unpublished) do
  name { FFaker::Name.name }
  published_at { nil }
end

Manifest.blueprint do
  device_model
  definition { DefaultManifest.definition }
end

Encounter.blueprint do
  institution { object.patient.try(:institution) || Institution.make }
  site { object.institution.sites.first || Site.make(institution: object.institution) }

  core_fields do
    fields = { "id" => "encounter-#{sn}" }
    fields["start_time"] = object.start_time if object.start_time
    fields
  end
end

def first_or_make_site_unless_manufacturer(institution)
  unless institution.kind_manufacturer?
    institution.sites.first || Site.make(institution: institution)
  end
end

SampleIdentifier.blueprint do
  sample do
    if object.site
      Sample.make(institution: object.site.institution)
    else
      Sample.make
    end
  end

  site do
    first_or_make_site_unless_manufacturer(object.sample.institution)
  end
end

Sample.blueprint do
  institution { object.encounter.try(:institution) || object.patient.try(:institution) || Institution.make! }
  patient { object.encounter.try(:patient) }
end

# FIXME: These properties should probably be part of the main blueprint, but that breaks a number of different existing specs.
Sample.blueprint(:filled) do
  institution { object.encounter.try(:institution) || object.patient.try(:institution) || Institution.make! }
  sample_identifiers { [SampleIdentifier.make!(sample: object)] }
  isolate_name { Faker::Name.name }
  specimen_role { "p" }
end

Sample.blueprint(:batch) do
  batch { Batch.make! }
end

QcInfo.blueprint do
  sample_qc { Sample.make(:batch) }
  uuid { object.sample_qc.uuid }
  batch_number { object.sample_qc.batch.batch_number }
  date_produced { object.sample_qc.date_produced }
end

AssayAttachment.blueprint do
  loinc_code { LoincCode.make }
  sample { Sample.make }
  result { Faker::Lorem.words(10) }
end

LoincCode.blueprint do
  loinc_number { "10000-#{sn}" }
  component { Faker::Lorem.words(4) }
end

TransferPackage.blueprint do
  uuid { SecureRandom.uuid }
  receiver_institution { Institution.make! }
  recipient { Faker::Name.name }
end

SampleTransfer.blueprint do
  sample { Sample.make!(:filled) }
  receiver_institution { Institution.make! }
  sender_institution { object.sample.institution || Institution.make! }
end

SampleTransfer.blueprint(:confirmed) do
  confirmed_at { Faker::Time.backward }
end

Batch.blueprint do
  institution { Institution.make }
  batch_number { "#{sn}" }
  isolate_name { 'ABC.42.DE' }
  date_produced { Time.strptime('01/01/2018', I18n.t('date.input_format.pattern')) }
  lab_technician { "Tec.Foo" }
  specimen_role { 'q' }
  inactivation_method { 'Formaldehyde' }
  volume { 100 }
end

Patient.blueprint do
  institution

  plain_sensitive_data {
    {}.tap do |h|
      h["id"] = object.entity_id || "patient-#{sn}"
      h["name"] = object.name if object.name
    end
  }
end

Patient.blueprint :phantom do
  name { FFaker::Name.name }
  plain_sensitive_data {
    {}.tap do |h|
      h["id"] = nil
      h["name"] = object.name if object.name
    end
  }
end

TestResult.blueprint do
  test_id { "test-#{sn}" }

  device_messages { [ DeviceMessage.make(device: object.device || Device.make) ] }
  device { object.device_messages.first.try(:device) || Device.make }
  institution { object.device.try(:institution) || Institution.make }
  sample_identifier { SampleIdentifier.make(site: object.device.try(:site), sample: Sample.make(institution: object.institution, patient: object.patient, encounter: object.encounter)) }

  encounter { object.sample.try(:encounter) }
  patient { object.sample.try(:patient) || object.encounter.try(:patient) }
end

DeviceMessage.blueprint do
  device
end

Policy.blueprint do
  name { FFaker::Name.name }
  granter { Institution.make!.user }
  definition { policy_definition(object.granter.institutions.first, CREATE_INSTITUTION, true) }
  user
end

Role.blueprint do
  name { FFaker::Name.name }
  policy
  institution
  site { Site.make institution: object.institution }
end

Subscriber.blueprint do
  user
  name { FFaker::Name.name }
  url { FFaker::Internet.uri("http") }
  last_run_at { Time.now }
end

Filter.blueprint do
  user
  name { FFaker::Name.name }
end

Site.blueprint do
  institution
  name { FFaker::Name.name }
  location_geoid { object.location.try(:id) || LocationService.repository.make.id }
  address { FFaker::Address.street_address }
  city { FFaker::Address.city }
  state { FFaker::AddressUS.state }
  zip_code { FFaker::AddressUS.zip_code }
  country { FFaker::Address.country }
  region { FFaker::AddressUS.state }
  lat { rand(-180..180) }
  lng { rand(-90..90) }
end

Site.blueprint :child do
  parent { nil }
  institution { object.parent.institution }
end

Location; class Location
  def self.make(params={})
    LocationService.repository.make(params)
  end

  def self.make!(params={})
    LocationService.repository.make(params)
  end
end
