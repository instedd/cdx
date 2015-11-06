require 'spec_helper'
require 'sidekiq/testing'

Sidekiq::Testing.fake!

describe DailyDemoData do
  
  before(:each) do
    user = User.create!email: "demo-user@demo.com", password: '11111111', password_confirmation: '11111111',  confirmed_at: Time.now
    institution = Institution.create! user_id: user.id, name: 'demo-institution'
    site =  Site.create! institution: institution, name: 'demo-site'

    device_model1 = DeviceModel.create! name: 'demo_fifo_model', published_at: 1.day.ago
    manifest1 = Manifest.create! device_model: device_model1, definition: IO.read(File.join(Rails.root, 'db', 'seeds', 'manifests', 'fio_manifest.json' ))
    device1 = Device.create! site: site, institution: site.institution , name: 'demo-device_fifo', serial_number: '123',  device_model:  manifest1.device_model, time_zone: "UTC"  

    device_model2 = DeviceModel.create! name: 'demo_cepheid_model', published_at: 1.day.ago
    manifest2 = Manifest.create! device_model: device_model2, definition: IO.read(File.join(Rails.root, 'db', 'seeds', 'manifests', 'cepheid_gene_xpert_manifest.json' ))
    device2 = Device.create! site: site, institution: site.institution , name: 'demo-device_cepheid', serial_number: '456',  device_model:  manifest2.device_model, time_zone: "UTC"  
  end
    
  let(:worker) { DailyDemoData.new }
  
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
