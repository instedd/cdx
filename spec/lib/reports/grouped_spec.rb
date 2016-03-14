require 'spec_helper'

RSpec.describe Reports::Grouped do
  class TestResult
    def self.execute
      {
        tests: [],
        total_count: 12
      }
    end
  end

  let(:current_user) { User.make }
  let(:site_user) { "#{current_user.first_name} #{current_user.last_name}" }
  let(:user_device) { Device.make institution_id: institution.id, site: site }
  let(:institution) { Institution.make(user_id: current_user.id) }
  let(:site) { Site.make(institution: institution) }
  let(:nav_context) { NavigationContext.new(current_user, site.uuid) }
  let(:filter) do
    {
      'institution.uuid' => institution.uuid,
      'site.path' => site.uuid,
      'since' => (Date.today - 1.year).iso8601
    }
  end
  let(:options) { {} }

  describe '.method_missing' do
    context 'when missing method matches by_* pattern' do
      context 'and is in the in hash of permitted methods' do
        describe '.by_error_code' do
          xit 'queries for tests grouped by error code' do
            filter['group_by'] = 'test.error_code'
            filter['test.status'] = 'error'
            allow(TestResult).to receive(:query).with(filter, current_user).and_return(TestResult)
            Reports::Grouped.by_error_code(current_user, nav_context)
          end
        end
      end

      context 'and is not in the in hash of permitted methods' do
        it 're-raises NoMethodError exeption' do
          expect{ Reports::Grouped.by_foo }.to raise_error(NoMethodError)
        end
      end
    end

    context 'when missing method does not match by_* pattern' do
      it 're-raises NoMethodError exeption' do
        expect{ Reports::Grouped.bar_error }.to raise_error(NoMethodError)
      end
    end
  end
end
