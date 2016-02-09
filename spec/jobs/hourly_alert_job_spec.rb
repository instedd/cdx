require 'spec_helper'
require 'sidekiq/testing'

Sidekiq::Testing.fake!


describe Api::TestsController, elasticsearch: true, validate_manifest: false do

  let(:user) {User.make}
  let(:institution) {Institution.make user_id: user.id}
  let(:worker) { HourlyAlertJob.new }

  context "end to end alert aggregation test" do
    before(:each) do
      @alert = Alert.make
      @alert.user = institution.user
      @alert.aggregation_type = Alert.aggregation_types.key(1)
      @alert_aggregated_frequency = Alert.aggregation_frequencies.key(0)
      @alert.aggregation_threshold = 99
      @alert.query = {"test.error_code"=>"155"}
      alert_recipient = AlertRecipient.new
      alert_recipient.recipient_type = AlertRecipient.recipient_types["internal_user"]
      alert_recipient.user = user
      alert_recipient.alert=@alert
      alert_recipient.save
      @alert.save
    end

    after(:each) do
      @alert.destroy
    end

    let(:parent_location) {Location.make}
    let(:leaf_location1) {Location.make parent: parent_location}
    let(:upper_leaf_location) {Location.make}

    let(:site1) {Site.make institution: institution, location_geoid: leaf_location1.id}

    it "for error code category inject an error code" do
      before_test_history_count = AlertHistory.count
      before_test_recipient_count=RecipientNotificationHistory.count

      @alert.create_percolator

      device1 = Device.make institution: institution, site: site1
      DeviceMessage.create_and_process device: device1, plain_text_data: (Oj.dump test:{assays:[result: :negative], error_code: 155}, sample: {id: 'a'}, patient: {id: 'a',gender: :male})
      worker.perform

      after_test_history_count = AlertHistory.count
      after_test_recipient_count= RecipientNotificationHistory.count
      
      expect(before_test_history_count+2).to eq(after_test_history_count)
      expect(before_test_recipient_count+1).to eq(after_test_recipient_count)
    end


  end

end
