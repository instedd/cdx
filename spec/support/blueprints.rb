require 'machinist/active_record'
require 'ffaker'
require_relative "../policy_spec_helper"

SampleSshKey = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC4'+
          'hzyCbJQ5RgrZPFz+rTscTuJ5NPuBIKiinXwkA38CE9+N37L8q9kMqxsbDumVFbamYVlS9fsmF1TqRRhobfJfZGpt'+
          'kcthQde83FWHQGaEQn8T4SG055N5SWNRjQTfMaK0uTTQ28BN44dhLluF/zp4UDHOKRVBrJY4SZq1M5ytkMc6mlZW'+
          'bCAzqtIUUJOMKz4lHn5Os/d8temlYskaKQ1n+FuX5qJXNr1SW8euH72fjQndu78DCwVNwnnrG+nEe3a9m2QwL5xn'+
          'X8f1ohAZ9IG41hwIOvB5UcrFenqYIpMPBCCOnizUcyIFJhegJDWh2oWlBo041emGOX3VCRjtGug3 fbulgarelli@Manass-MacBook-2.local'

# NOTE: fixes compatibility with Ruby 2.4 (Fixnum is deprecated, use Integer)
module Machinist
  class Lathe
    protected

    def make_attribute(attribute, args, &block) #:nodoc:
      count = args.shift if args.first.is_a?(Integer)
      if count
        Array.new(count) { make_one_value(attribute, args, &block) }
      else
        make_one_value(attribute, args, &block)
      end
    end
  end

  module Machinable
    private

    def decode_args_to_make(*args) #:nodoc:
      shift_arg = lambda {|klass| args.shift if args.first.is_a?(klass) }
      count      = shift_arg[Integer]
      name       = shift_arg[Symbol] || :master
      attributes = shift_arg[Hash]   || {}
      raise ArgumentError.new("Couldn't understand arguments") unless args.empty?

      @blueprints ||= {}
      blueprint = @blueprints[name]
      raise NoBlueprintError.new(self, name) unless blueprint

      if count.nil?
        yield(blueprint, attributes)
      else
        Array.new(count) { yield(blueprint, attributes) }
      end
    end
  end
end

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
  unless institution.try &:kind_manufacturer?
    institution.try { |i| i.sites.first } || Site.make(institution: institution)
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
  original_batch_id { object.batch_id }
end

# FIXME: These properties should probably be part of the main blueprint, but that breaks a number of different existing specs.
Sample.blueprint(:filled) do
  institution { object.encounter.try(:institution) || object.patient.try(:institution) || Institution.make! }
  sample_identifiers { [SampleIdentifier.make!(sample: object)] }
  isolate_name { Faker::Name.name }
  specimen_role { "p" }
  date_produced { Faker::Time.backward }
  measured_signal { 10.0 }
  original_batch_id { object.batch_id }
end

Sample.blueprint(:batch) do
  batch { Batch.make! }
  original_batch_id { object.batch_id }
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
  sender_institution { Institution.make! }
  recipient { Faker::Name.name }
  box_transfers { [BoxTransfer.make(transfer_package: object)] }
end

TransferPackage.blueprint(:confirmed) do
  confirmed_at { Faker::Time.backward }
end

TransferPackage.blueprint(:receiver_confirmed) do
  confirmed_at { Faker::Time.backward }
  box_transfers { [
    BoxTransfer.make(
      transfer_package: object,
      box: Box.make(:overfilled_blinded, institution: object.receiver_institution )
    )
  ] }
end

TransferPackage.blueprint(:blinded) do
  box_transfers { [
    BoxTransfer.make(
      transfer_package: object,
      box: Box.make(:blinded, institution: object.receiver_institution )
    )
  ] }
end

Batch.blueprint do
  institution { Institution.make }
  batch_number { "#{sn}" }
  isolate_name { 'ABC.42.DE' }
  date_produced { Time.zone.local(2018, 1, 1) }
  lab_technician { "Tec.Foo" }
  specimen_role { 'q' }
  inactivation_method { 'Formaldehyde' }
  volume { 100 }
end

Batch.blueprint(:qc_sample) do
  samples { [Sample.make(specimen_role: 'q')] }
end

Box.blueprint do
  institution { object.site.try(&:institution) || Institution.make }
  purpose { "LOD" }
end

Box.blueprint(:filled) do
  samples { [
    Sample.make(:filled, box: object, institution: object.institution, site: object.site),
    Sample.make(:filled, box: object, institution: object.institution, site: object.site),
  ] }
end

Box.blueprint(:filled_without_measurements) do
  samples { [
    Sample.make(:filled, box: object, institution: object.institution, site: object.site, measured_signal: nil),
    Sample.make(:filled, box: object, institution: object.institution, site: object.site, measured_signal: nil),
  ] }
end

Box.blueprint(:overfilled) do
  @batch_one = Batch.make!
  @batch_two = Batch.make!

  samples { [
    Sample.make(:filled, box: object, institution: object.institution, site: object.site, batch: @batch_one, concentration: 30, replicate: 1, distractor: true),
    Sample.make(:filled, box: object, institution: object.institution, site: object.site, batch: @batch_two, concentration: 200, replicate: 2, distractor: false),
    Sample.make(:filled, box: object, institution: object.institution, site: object.site, batch: @batch_one, concentration: 1000, replicate: 3, distractor: true),
    Sample.make(:filled, box: object, institution: object.institution, site: object.site, batch: @batch_two, concentration: 30, replicate: 4, distractor: false),
    Sample.make(:filled, box: object, institution: object.institution, site: object.site, batch: @batch_one, concentration: 200, replicate: 5, distractor: true),
    Sample.make(:filled, box: object, institution: object.institution, site: object.site, batch: @batch_two, concentration: 1000, replicate: 6, distractor: false),
    Sample.make(:filled, box: object, institution: object.institution, site: object.site, batch: @batch_one, concentration: 30, replicate: 7, distractor: true),
    Sample.make(:filled, box: object, institution: object.institution, site: object.site, batch: @batch_two, concentration: 200, replicate: 8, distractor: false),
    Sample.make(:filled, box: object, institution: object.institution, site: object.site, batch: @batch_one, concentration: 1000, replicate: 9, distractor: true),
  ] }
end

Box.blueprint(:lob_lod) do
  @batch_one = Batch.make!
  @batch_two = Batch.make!

  samples { [
    Sample.make(:filled, box: object, institution: object.institution, site: object.site, batch: @batch_one, concentration: 0, replicate: 1, measured_signal: 10),
    Sample.make(:filled, box: object, institution: object.institution, site: object.site, batch: @batch_two, concentration: 10, replicate: 2, measured_signal:100.12),
    Sample.make(:filled, box: object, institution: object.institution, site: object.site, batch: @batch_one, concentration: 10, replicate: 3, measured_signal:193.5),
    Sample.make(:filled, box: object, institution: object.institution, site: object.site, batch: @batch_two, concentration: 10, replicate: 4, measured_signal:100.12),
    Sample.make(:filled, box: object, institution: object.institution, site: object.site, batch: @batch_one, concentration: 20, replicate: 5, measured_signal:193.5),
    Sample.make(:filled, box: object, institution: object.institution, site: object.site, batch: @batch_two, concentration: 0, replicate: 6, measured_signal:3.3),
  ] }
end

Box.blueprint(:lob_lod_without_measured_signal) do
  @batch_one = Batch.make!
  @batch_two = Batch.make!

  samples { [
    Sample.make(:filled, box: object, institution: object.institution, site: object.site, batch: @batch_one, concentration: 0, replicate: 1),
    Sample.make(:filled, box: object, institution: object.institution, site: object.site, batch: @batch_two, concentration: 10, replicate: 2, measured_signal:100.12),
    Sample.make(:filled, box: object, institution: object.institution, site: object.site, batch: @batch_one, concentration: 10, replicate: 3, measured_signal:193.5),
    Sample.make(:filled, box: object, institution: object.institution, site: object.site, batch: @batch_two, concentration: 10, replicate: 4, measured_signal:100.12),
    Sample.make(:filled, box: object, institution: object.institution, site: object.site, batch: @batch_one, concentration: 20, replicate: 5),
    Sample.make(:filled, box: object, institution: object.institution, site: object.site, batch: @batch_two, concentration: 0, replicate: 6, measured_signal:3.3),
  ] }
end

Box.blueprint(:blinded) do
  samples { [
    Sample.make(:filled, box: object, institution: object.institution, site: object.site),
    Sample.make(:filled, box: object, institution: object.institution, site: object.site),
  ] }
  blinded { true }
end

Box.blueprint(:overfilled_blinded) do
  @batch_one = Batch.make!
  @batch_two = Batch.make!

  samples { [
    Sample.make(:filled, box: object, institution: object.institution, site: object.site, batch: @batch_one, concentration: 30, replicate: 1),
    Sample.make(:filled, box: object, institution: object.institution, site: object.site, batch: @batch_two, concentration: 200, replicate: 2),
    Sample.make(:filled, box: object, institution: object.institution, site: object.site, batch: @batch_one, concentration: 1000, replicate: 3),
    Sample.make(:filled, box: object, institution: object.institution, site: object.site, batch: @batch_two, concentration: 30, replicate: 4),
    Sample.make(:filled, box: object, institution: object.institution, site: object.site, batch: @batch_one, concentration: 200, replicate: 5),
    Sample.make(:filled, box: object, institution: object.institution, site: object.site, batch: @batch_two, concentration: 1000, replicate: 6),
    Sample.make(:filled, box: object, institution: object.institution, site: object.site, batch: @batch_one, concentration: 30, replicate: 7),
    Sample.make(:filled, box: object, institution: object.institution, site: object.site, batch: @batch_two, concentration: 200, replicate: 8),
    Sample.make(:filled, box: object, institution: object.institution, site: object.site, batch: @batch_one, concentration: 1000, replicate: 9),
  ] }
  blinded { true }
end

BoxTransfer.blueprint do
  box { Box.make(:filled, institution: nil, site: nil) }
  transfer_package { TransferPackage.make }
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
