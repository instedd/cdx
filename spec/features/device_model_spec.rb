require 'spec_helper'

describe "device model" do
  let!(:institution) { Institution.make(:manufacturer) }
  let(:user) { institution.user }
  before(:each) { sign_in(user) }

  it "can create model and access to it's details", testrail: 424 do
    goto_page NewDeviceModelPage do |page|
      page.name.set "MyModel"
      page.support_url.set "example.org/support"
      page.manifest.attach "db/seeds/manifests/genoscan_manifest.json"
      page.submit
    end

    expect_page DeviceModelsPage do |page|
      page.table.items.first.tap do |item|
        expect(item).to have_content("MyModel")
        item.click
      end
    end

    expect_page DeviceModelPage do |page|
      expect(page.name.value).to eq("MyModel")
    end
  end

  context "device model view" do
    let!(:device_model) {DeviceModel.make(institution: institution)}
    let!(:manifest) {Manifest.make(device_model: device_model)}
    
    it "can rename device model", testrail: 425 do
      goto_page DeviceModelsPage do |page|
        page.table.items.first.click
      end

      expect_page DeviceModelPage do |page|
        page.name.set "Renamed_Model"
        page.submit
      end 

      expect_page DeviceModelsPage do |page|
        page.table.items.first.tap do |item|
          expect(item).to have_content("Renamed_Model")
          item.click
        end
      end

      expect_page DeviceModelPage do |page|
        expect(page.name.value).to eq("Renamed_Model")
      end
    end

    it "should withdraw device model", testrail: 1395 do
      goto_page DeviceModelsPage do |page|
        page.table.items.first.click
      end

      expect_page DeviceModelPage do |page|
        expect(page).to have_content("This device model is published") 
        page.accept_confirm do
          page.press_secondary_button
        end
      end 

      expect_page DeviceModelsPage do |page|
        page.table.items.first.click
        expect(page).to have_content("This device model is not yet published")
      end
    end
  end

end
