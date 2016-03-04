require 'spec_helper'

RSpec.describe Reports::Base do
  class DummyReport < Reports::Base; end

  class TestResult
    def self.execute; end
  end

  let(:current_user) { User.make }
  let(:site_user) { "#{current_user.first_name} #{current_user.last_name}" }
  let(:user_device) { Device.make institution_id: institution.id, site: site }
  let(:institution) { Institution.make(user_id: current_user.id) }
  let(:site) { Site.make(institution: institution) }
  let(:query) { {} }
  let(:options) { {} }
  let(:since) { (Date.today - 1.year).iso8601 }


  describe 'contextual query' do
    before do
      options['since'] = since
      query['since'] = since
    end

    context 'when navigation context is a Site' do
      let(:nav_context) { NavigationContext.new(current_user, site.uuid) }
      it 'queries for site.path and institution.id' do
        query['institution.uuid'] = institution.uuid
        query['site.path'] = site.uuid
        query['test.type'] = "specimen"
        allow(TestResult).to receive(:query).with(query, current_user).and_return(TestResult)
        DummyReport.process(current_user, nav_context, options)
      end
    end

    context 'when navigation context is an Institution' do
      let(:nav_context) { NavigationContext.new(current_user, institution.uuid) }
      it 'queries for institution.uuid' do
        query['institution.uuid'] = institution.uuid
        query['test.type'] = "specimen"
        allow(TestResult).to receive(:query).with(query, current_user).and_return(TestResult)
        DummyReport.process(current_user, nav_context, options)
      end
    end
  end

  describe 'date range' do
    let(:nav_context) { NavigationContext.new(current_user, institution.uuid) }
    context 'when no date given' do
      it 'defaults to 1 year ago' do
        query['institution.uuid'] = institution.uuid
        query['since'] = since
        query['test.type'] = "specimen"
        allow(TestResult).to receive(:query).with(query, current_user).and_return(TestResult)
        DummyReport.process(current_user, nav_context, options)
      end
    end

    context 'when single specific date given' do
      it 'includes that date in query' do
        query['institution.uuid'] = institution.uuid
        query['since'] = '2005-12-12'
        query['test.type'] = "specimen"
        options['since'] = '2005-12-12'
        allow(TestResult).to receive(:query).with(query, current_user).and_return(TestResult)
        DummyReport.process(current_user, nav_context, options)
      end
    end

    context 'when range of dates given' do
      let(:date_range) do
        range = {}
        range['start_time'] = {}
        range['start_time']['gte'] = :some_start_date
        range['start_time']['lte'] = :some_end_date
        range
      end

      it 'includes them in the query' do
        query['institution.uuid'] = institution.uuid
        query['range'] = date_range
        query['test.type'] = "specimen"
        options['date_range'] = date_range
        allow(TestResult).to receive(:query).with(query, current_user).and_return(TestResult)
        DummyReport.process(current_user, nav_context, options)
      end

      it 'does not include :since in query' do
        query['institution.uuid'] = institution.uuid
        query['range'] = date_range
        query['test.type'] = "specimen"
        options['date_range'] = date_range
        options['since'] = since
        allow(TestResult).to receive(:query).with(query, current_user).and_return(TestResult)
        DummyReport.process(current_user, nav_context, options)
      end
    end

    context 'when the range is a week' do
      before do
        6.downto(0).each do |i|
          TestResult.create_and_index(
            core_fields: {
              'assays' => ['condition' => 'mtb', 'result' => :positive],
              'start_time' => Date.today - i.days,
              'name' => 'mtb',
              'status' => 'error',
              'site_user' => site_user
            },
            device_messages: [DeviceMessage.make(device: user_device)]
          )
        end
      end

      it 'can sort the results by day' do
        options['since'] = (Date.today - 7.days).iso8601
        tests = DummyReport.process(
          current_user, nav_context, options
        ).sort_by_day
        expect(tests.data.count).to eq(7)
        expect(tests.data.first[:label]).to eq((Date.today - 6.days).strftime('%d/%m'))
        expect(tests.data.last[:label]).to eq(Date.today.strftime('%d/%m'))
      end
    end

    context 'when the range is a day' do
      before do
        23.downto(0).each do |i|
          #do two times each hour [could not do more due to,DEFAULT_PAGE_SIZE = 50, limit]
          (0..1).each do |inner|
            TestResult.create_and_index(
              core_fields: {
                'assays' => ['condition' => 'mtb', 'result' => :positive],
                'start_time' => Date.today - i.hours,
                'name' => 'mtb',
                'status' => 'error',
                'site_user' => site_user
              },
              device_messages: [DeviceMessage.make(device: user_device)]
            )
          end
        end
      end

      it 'can sort the results by hour' do
        options['date_range'] = {}
        options['date_range']['timestamp'] = { gt: 'now-24h' }
        @data = DummyReport.process(
          current_user, nav_context, options
        ).sort_by_hour
        expect(@data).to be_a(Array)
        expect(@data.count).to eq(24)
      end
    end
  end
end
