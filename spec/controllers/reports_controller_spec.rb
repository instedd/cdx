require "spec_helper"

describe ReportsController do
  let(:current_user) { User.make }
  let(:work_group) { WorkGroup.make(user: current_user) }
  let(:facility) { Facility.make(work_group: work_group) }
  let(:report) { ElasticRecord.for work_group.index_name, 'report' }

  before(:each) { sign_in current_user }
  after(:each) {Elasticsearch::Client.new(log: false).indices.delete index: work_group.index_name}

  it 'Should notify subscribers' do
    Subscriber.create! name: 'foo', callback_url: 'bar'
    post :create, report: {facility_id: facility.id, result: 'positive', test_id: '12345', patient_id: '123'}, format: :json

    report.first.properties[:facility_id].should eq(facility.id)
    report.first.properties[:result].should eq('positive')
    report.first.properties[:test_id].should eq('12345')
    report.first.properties[:patient_id].should eq('123')
  end
end
