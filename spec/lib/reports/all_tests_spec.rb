require 'spec_helper'

RSpec.describe Reports::AllTests, elasticsearch: true do
  let(:current_user) { User.make }
  let(:institution) { Institution.make(user: current_user) }
  let(:site) { Site.make(institution: institution) }
  let(:current_user_two) { User.make }
  let(:institution_two) { Institution.make(user: current_user_two) }
  let(:site_two) { Site.make(institution: institution_two) }
  let(:user_device) { Device.make institution: institution, site: site }
  let(:user_device_two) { Device.make institution: institution_two, site: site_two }

  let(:nav_context) { NavigationContext.new(current_user, institution.uuid) }
  let(:options) { {} }

  before do
    TestResult.create_and_index(
      core_fields: {
        'assays' => ['condition' => 'mtb', 'result' => :positive],
        'start_time' => Time.now,
        'type' => 'specimen',
        'name' => 'mtb',
        'status' => 'success'
      },
      device_messages:[DeviceMessage.make(device: user_device)]
    )

    TestResult.create_and_index(
      core_fields: {
        'assays' => ['condition' => 'mtb', 'result' => :positive],
        'start_time' => Time.now - 1.day,
        'type' => 'specimen',
        'name' => 'mtb',
        'status' => 'error'
      },
      device_messages:[DeviceMessage.make(device: user_device)]
    )

    TestResult.create_and_index(
      core_fields: {
        'assays' => ['condition' => 'mtb', 'result' => :negative],
        'start_time' => Time.now - 1.month,
        'type' => 'specimen',
        'name' => 'mtb',
        'status' => 'success'
      },
      device_messages:[DeviceMessage.make(device: user_device)]
    )

    TestResult.create_and_index(
      core_fields: {
        'assays' => ['condition' => 'man_flu', 'result' => :negative],
        'start_time' => Time.now - 1.month,
        'type' => 'specimen',
        'name' => 'man_flu',
        'status' => 'error'
      },
      device_messages:[DeviceMessage.make(device: user_device)]
    )

    TestResult.create_and_index(
      core_fields: { 'assays' => ['condition' => 'mtb', 'result' => :negative ], 'type' => 'specimen' },
      device_messages:[DeviceMessage.make(device: user_device_two)]
    )

    refresh_index
  end

  describe 'process results' do
    before do
      @tests = Reports::AllTests.process(current_user, nav_context)
    end

    it 'scopes results by site and user' do
      expect(@tests.results['total_count']).to eq(4)
    end

    it 'can sort results by month' do
      sorted = @tests.sort_by_month.data
      expect(sorted.size).to eq(12)
    end

    describe 'statuses' do
      it 'includes :error' do
        expect(@tests.statuses).to include('error')
      end

      it 'includes :success' do
        expect(@tests.statuses).to include('success')
      end
    end

    context 'when date range is a week' do
      before do
        options['since'] = (Date.today - 7.days).iso8601
        @tests = Reports::AllTests.process(current_user, nav_context, options)
      end

      it 'scopes results by site and user' do
        expect(@tests.results['total_count']).to eq(2)
      end

      it 'can sort results by day' do
        sorted = @tests.sort_by_day.data
        expect(sorted.size).to eq(7)
      end
    end
  end
end
