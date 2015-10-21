require 'spec_helper'
require 'sidekiq/testing'

Sidekiq::Testing.fake!

describe DailyDemoData do

  let(:worker) { DailyDemoData.new }
  
  describe '#perform' do
    it "generates demo data when enabled" do      
      ENV['USE_DEMO_DATA']='true'

      allow(worker).to receive("get_repeat_demo_per_device").and_return(4)
      expect(TestResult.count).to be(0)  
      worker.perform
      expect(TestResult.count).to be(4)  
    end
    
    it "generates no demo data when disabled" do      
      ENV['USE_DEMO_DATA']=nil

      allow(worker).to receive("get_repeat_demo_per_device").and_return(4)
      expect(TestResult.count).to be(0)  
      worker.perform
      expect(TestResult.count).to be(0)  
      end
      
  end
end
