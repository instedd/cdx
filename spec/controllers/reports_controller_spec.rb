require "spec_helper"

describe ReportsController do
  let(:current_user) { User.make }
  let(:work_group) { WorkGroup.make(user: current_user) }
  let(:device) { Device.make(work_group: work_group) }
  let(:report) { ElasticRecord.for work_group.index_name, 'report' }

  before(:each) { sign_in current_user }
  after(:each) {Elasticsearch::Client.new(log: false).indices.delete index: work_group.index_name}

  it 'Should notify subscribers' do
    FakeWeb.register_uri(:get, "http://mbuilder.instedd.org:3001/external/application/3/trigger/asd?auth_token=4Q5E6RLZoLDbs0Gk3JqiQ5--GCLt7lLyBD37c-2l8Ys&data='device_id':'#{device.id}','result':'positive','test_id':'12345','patient_id':'123'", :body => "todo ok", :status => ["200", "OK"], :content_type => "application/json; charset=utf-8")

    work_group.subscribers.create! name: 'foo', callback_url: 'http://mbuilder.instedd.org:3001/external/application/3/trigger/asd', auth_token: '4Q5E6RLZoLDbs0Gk3JqiQ5--GCLt7lLyBD37c-2l8Ys'

    post :create, report: {device_id: device.id, result: 'positive', test_id: '12345', patient_id: '123'}, format: :json

    FakeWeb.last_request.method.should eq("GET")
    FakeWeb.last_request['host'].should eq("mbuilder.instedd.org:3001")

    report.first.properties[:device_id].should eq(device.id)
    report.first.properties[:result].should eq('positive')
    report.first.properties[:test_id].should eq('12345')
    report.first.properties[:patient_id].should eq('123')
  end
end
