require 'spec_helper'

RSpec.describe Alert, :type => :model, elasticsearch: true do
   let!(:user) { User.make }
   

   let(:model){DeviceModel.make}
   let(:device){Device.make device_model: model}
   let(:device_message){DeviceMessage.make(device: device)}
   let(:institution){device.institution}
   let(:site){device.site}
   
  context "validates fields" do
    it "cannot create for missing fields" do
     alert = Alert.create    
 
      expect(alert).to_not be_valid
    end
    
    it "can create alert" do
      alert = Alert.make
      expect(alert).to be_valid
    end
       
  end
  
  context "validate perculator" do
    
    it "creates a perculator" do
      alert = Alert.make 
      alert.query = {"test.error_code"=>"155"}
      alert.user = institution.user
      result = Cdx::Api.client.search index: Cdx::Api.index_name_pattern, type: '.percolator'
      before_count=result["hits"]["total"] 

      alert.create_percolator
      result = Cdx::Api.client.search index: Cdx::Api.index_name_pattern, type: '.percolator'
      expect(result["hits"]["total"]).to eq(before_count+1)
   end 
  end
  
  
  it "updates percolator when the alert query changes" do
    alert = Alert.make 
    alert.query = {"test.error_code"=>"155"}
    alert.user = institution.user
    
    alert.update_attributes! query: {"test.assays.condition" => "mtb"}
    percolator = Cdx::Api.client.get index: Cdx::Api.index_name_pattern, type: '.percolator', id: "alert_"+alert.id.to_s    
    expect(percolator["_source"]).to eq({query: TestResult.query(alert.query, alert.user).elasticsearch_query, type: 'test'}.with_indifferent_access)
  end
  
  
  it "deletes percolator when the alert is deleted" do
    alert = Alert.make 
    alert.query = {"test.error_code"=>"155"}
    alert.user = institution.user
    
    alert.create_percolator
    result = Cdx::Api.client.search index: Cdx::Api.index_name_pattern, type: '.percolator'

    alert.destroy
    refresh_index
    result = Cdx::Api.client.search index: Cdx::Api.index_name_pattern, type: '.percolator'
    expect(result["hits"]["total"]).to eq(0)
  end
  
  
end


