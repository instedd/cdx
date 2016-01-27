require 'spec_helper'

RSpec.describe AlertRecipient, :type => :model do
  let!(:user) { User.make }

  context "validates fields" do
    it "cannot create for invalid name fields" do
      alert = Alert.create
      alertRecipient = AlertRecipient.new
      alertRecipient.recipient_type = AlertRecipient.recipient_types["external_user"]
      alertRecipient.email = "aa@bb.com"
      alertRecipient.telephone = "12456"
      alertRecipient.first_name = ""
      alertRecipient.last_name = "s"
      alertRecipient.alert=alert

      expect(alertRecipient).to_not be_valid
    end

    it "cannot create for invalid email field" do
      alert = Alert.create
      alertRecipient = AlertRecipient.new
      alertRecipient.recipient_type = AlertRecipient.recipient_types["external_user"]
      alertRecipient.email = "aa"
      alertRecipient.alert=alert

      expect(alertRecipient).to_not be_valid
    end
    
      it "cannot create for invalid telephone field" do
        alert = Alert.create
        alertRecipient = AlertRecipient.new
        alertRecipient.recipient_type = AlertRecipient.recipient_types["external_user"]
        alertRecipient.telephone = "124a56"

        alertRecipient.alert=alert

        expect(alertRecipient).to_not be_valid
      end

    it "cannot create for empty email and telephone fields" do
      alert = Alert.create
      alertRecipient = AlertRecipient.new
      alertRecipient.recipient_type = AlertRecipient.recipient_types["external_user"]
      alertRecipient.email = ""
      alertRecipient.telephone = ""
      alertRecipient.alert=alert

      expect(alertRecipient).to_not be_valid
    end


    it "can create for valid fields" do
      alert = Alert.create
      alertRecipient = AlertRecipient.new
      alertRecipient.recipient_type = AlertRecipient.recipient_types["external_user"]
      alertRecipient.email = "aa@bb.com"
      alertRecipient.telephone = "12456"
      alertRecipient.first_name = "sadasdsdas"
      alertRecipient.last_name = "sssssss"
      alertRecipient.alert=alert

      expect(alertRecipient).to be_valid
    end

  end



end
