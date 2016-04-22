require 'spec_helper'

RSpec.describe Reports::Errors, elasticsearch: true do
  let(:current_user) { User.make }
  let(:site_user) { "#{current_user.first_name} #{current_user.last_name}" }
  let(:institution) { Institution.make(user_id: current_user.id) }
  let(:site) { Site.make(institution: institution) }
  let(:current_user_two) { User.make }
  let(:institution_two) { Institution.make(user_id: current_user_two.id) }
  let(:site_two) { Site.make(institution: institution_two) }
  let(:user_device) { Device.make institution_id: institution.id, site: site }
  let(:user_device_two) { Device.make institution_id: institution_two.id, site: site_two }

  let(:nav_context) { NavigationContext.new(current_user, institution.uuid) }

  before do
    TestResult.create_and_index(
      core_fields: {
        'assays' => ['condition' => 'mtb', 'result' => :positive],
        'start_time' => Time.now,
        'name' => 'mtb',
        'status' => 'error',
        'error_code' => 300,
        'type' => 'specimen',
        'site_user' => site_user
      },
      device_messages: [DeviceMessage.make(device: user_device)]
    )

    TestResult.create_and_index(
      core_fields: {
        'assays' => ['condition' => 'mtb', 'result' => :negative],
        'start_time' => Time.now - 1.month,
        'name' => 'mtb',
        'status' => 'error',
        'error_code' => 300,
        'type' => 'specimen',
        'site_user' => site_user
      },
      device_messages: [DeviceMessage.make(device: user_device)]
    )

    TestResult.create_and_index(
      core_fields: {
        'assays' => ['condition' => 'man_flu', 'result' => :negative],
        'start_time' => Time.now - 1.month,
        'name' => 'man_flu',
        'status' => 'error',
        'error_code' => 200,
        'type' => 'specimen'
      },
      device_messages: [DeviceMessage.make(device: user_device)]
    )

    TestResult.create_and_index(
      core_fields: { 'assays' => ['condition' => 'mtb', 'result' => :negative] },
      device_messages: [DeviceMessage.make(device: user_device_two)]
    )

    TestResult.create_and_index(
      core_fields: {
        'assays' => ['condition' => 'man_flu', 'result' => :negative],
        'start_time' => Time.now - 1.month,
        'reported_time' => Time.now + 1.hour,
        'name' => 'man_flu',
        'status' => 'success'
      },
      device_messages: [DeviceMessage.make(device: user_device)]
    )

      TestResult.create_and_index(
        core_fields: {
          'assays' => ['condition' => 'man_flu1', 'result' => :negative],
          'start_time' => Time.now - 1.month,
          'reported_time' => Time.now + 1.hour,
          'name' => 'man_flu1',
          'status' => 'no_result'
        },
        device_messages: [DeviceMessage.make(device: user_device)]
      )

      TestResult.create_and_index(
        core_fields: {
          'assays' => ['condition' => 'man_flu2', 'result' => :negative],
          'start_time' => Time.now - 1.month,
          'reported_time' => Time.now + 1.hour,
          'name' => 'man_flu2',
          'status' => 'in_progress'
        },
        device_messages:[DeviceMessage.make(device: user_device)]
      )

      TestResult.create_and_index(
        core_fields: {
          'assays' => ['condition' => 'man_flu4', 'result' => :negative],
          'start_time' => Time.now - 1.month,
          'reported_time' => Time.now + 1.hour,
          'name' => 'man_flu4',
          'status' => 'invalid'
        },
        device_messages:[DeviceMessage.make(device: user_device)]
      )

      refresh_index
  end

  describe 'process results' do
    before do
      @tests = Reports::Errors.process(current_user, nav_context)
    end

    it 'finds 2 tests when scoped to user/site one' do
      expect(@tests.results['total_count']).to eq(3)
    end

    it 'includes the relevant :error_code' do
      expect(@tests.error_codes).to include(200)
      expect(@tests.error_codes).to include(300)
    end
  end
end
