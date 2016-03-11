require 'spec_helper'

RSpec.describe Reports::AllTests, elasticsearch: true do
  let(:current_user) { User.make }
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
        'type' => 'specimen',
        'name' => 'mtb'
      },
      device_messages:[DeviceMessage.make(device: user_device)]
    )

    TestResult.create_and_index(
      core_fields: {
        'assays' => ['condition' => 'mtb', 'result' => :negative],
        'start_time' => Time.now - 1.month,
        'type' => 'specimen',
        'name' => 'mtb'
      },
      device_messages:[DeviceMessage.make(device: user_device)]
    )

    TestResult.create_and_index(
      core_fields: {
        'assays' => ['condition' => 'man_flu', 'result' => :negative],
        'start_time' => Time.now - 1.month,
        'type' => 'specimen',
        'name' => 'man_flu'
      },
      device_messages:[DeviceMessage.make(device: user_device)]
    )

    TestResult.create_and_index(
      core_fields: { 'assays' => ['condition' => 'mtb', 'result' => :negative ], 'type' => 'specimen' },
      device_messages:[DeviceMessage.make(device: user_device_two)]
    )

    refresh_index
  end

  describe 'process results and sort by month' do
    xit 'finds 3 tests when scoped to user/site one' do
      results = Reports::AllTests.process(current_user, nav_context).sort_by_month
      count = results.data.map { |x| x[:values].sum }.sum
      expect(count).to eq(3)
    end
  end

  describe '.by_name' do
    it 'groups tests by name in current context' do
      data = Reports::AllTests.by_name(current_user, nav_context)
      expect(data).to include({ :label => 'mtb', :value => 2 })
      expect(data).to include({ :label => 'man_flu', :value => 1 })
    end
  end
end
