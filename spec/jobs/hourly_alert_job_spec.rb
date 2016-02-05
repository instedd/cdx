require 'spec_helper'
require 'sidekiq/testing'

Sidekiq::Testing.fake!

describe HourlyAlertJob do
  
  before(:each) do
=begin
    user = User.make 
    model = DeviceModel.make
    device = Device.make device_model: model
    device_message = DeviceMessage.make(device: device)
    institution = device.institution
    site = device.site
    
     alert = Alert.make
      alert.query = {"test.error_code"=>"155"}
      alert.user = institution.user
  binding.pry
  # Alert.aggregation_frequencies.key(0)
  # Alert.aggregation_frequencies["hour"]
  
  
      alert.aggregation_type = Alert.aggregation_types.key(1)
      alert_aggregated_frequency = Alert.aggregation_frequencies.key(0)
      alert.aggregation_threshold = 99
      result = Cdx::Api.client.search index: Cdx::Api.index_name_pattern, type: '.percolator'
      alert.create_percolator
=end     
     end
    
  let(:worker) { DailyAlertJob.new }
  
  describe '#perform' do
    it "prococesses alert" do      

=begin
   DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[result: :negative], error_code: 155}, sample: {id: 'a'}, patient: {id: 'a',gender: :male})
   
   
    #  allow(worker).to receive("get_repeat_demo_per_device").and_return(4)
     # expect(TestResult.count).to eq(0)  
     binding.pry
      worker.perform
    #  expect(TestResult.count).to eq(4)  
=end
    end
    
      
  end
end
