require 'spec_helper'
require 'sidekiq/testing'

Sidekiq::Testing.fake!

describe HourlyAlert do
  
  before(:each) do
    user = User.make 
    model = DeviceModel.make
    device = Device.make device_model: model
    device_message = DeviceMessage.make(device: device)
    institution = device.institution
    site = device.site
    
     alert = Alert.make
      alert.query = {"test.error_code"=>"155"}
      alert.user = institution.user
      result = Cdx::Api.client.search index: Cdx::Api.index_name_pattern, type: '.percolator'
      alert.create_percolator
      
     end
    
  let(:worker) { DailyAlertJob.new }
  
  describe '#perform' do
    it "generates demo data when enabled" do      
      ENV['USE_DEMO_DATA']='true'

      allow(worker).to receive("get_repeat_demo_per_device").and_return(4)
      expect(TestResult.count).to eq(0)  
      worker.perform
      expect(TestResult.count).to eq(4)  
    end
    
    it "generates no demo data when disabled" do      
      ENV['USE_DEMO_DATA']=nil

      allow(worker).to receive("get_repeat_demo_per_device").and_return(4)
      expect(TestResult.count).to eq(0)  
      worker.perform
      expect(TestResult.count).to eq(0)  
      end
      
  end
end
