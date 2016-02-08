require 'spec_helper'

RSpec.describe Reports::Base do
  class DummyReport < Reports::Base; end

  class TestResult
    def self.execute; end
  end

  let(:current_user) { User.make }
  let(:institution) { Institution.make(user_id: current_user.id) }
  let(:site) { Site.make(institution: institution) }
  let(:query) { {} }
  let(:options) { {} }
  let(:since) { (Date.today - 1.year).iso8601 }

  before do
    options['since'] = since
    query['since'] = since
  end

  describe 'contextual query' do
    context 'when navigation context is a Site' do
      let(:nav_context) { NavigationContext.new(current_user, site.uuid) }
      it 'queries for site.path and institution.id' do
        query['institution.uuid'] = institution.uuid
        query['site.path'] = site.uuid
        allow(TestResult).to receive(:query).with(query, current_user).and_return(TestResult)
        DummyReport.process(current_user, nav_context, options)
      end
    end

    context 'when navigation context is an Institution' do
      let(:nav_context) { NavigationContext.new(current_user, institution.uuid) }
      it 'queries for institution.uuid' do
        query['institution.uuid'] = institution.uuid
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
        options.delete('since')
        allow(TestResult).to receive(:query).with(query, current_user).and_return(TestResult)
        DummyReport.process(current_user, nav_context, options)
      end
    end

    context 'when date given' do
      it 'includes that date in query' do
        query['institution.uuid'] = institution.uuid
        query['since'] = '2005-12-12'
        options['since'] = '2005-12-12'
        allow(TestResult).to receive(:query).with(query, current_user).and_return(TestResult)
        DummyReport.process(current_user, nav_context, options)
      end
    end
  end
end
