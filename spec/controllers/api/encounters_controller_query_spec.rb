require 'spec_helper'

describe Api::EncountersController, elasticsearch: true, validate_manifest: false do

  let(:user) { User.make }
  let!(:institution) { Institution.make user_id: user.id }
  let(:site) { Site.make institution: institution }
  let(:device) { Device.make institution: institution, site: site }
  let(:data) { Oj.dump test:{assays: [result: :positive]} }
  before(:each) { sign_in user }

  def get_updates(options, body="")
    refresh_index
    response = get :index, body, options.merge(format: 'json')
    expect(response.status).to eq(200)
    Oj.load(response.body)["encounters"]
  end

  context "Query" do
    context "Policies" do
      it "allows a user to query encounters of it's own institutions" do
        device2 = Device.make

        DeviceMessage.create_and_process device: device, plain_text_data: (Oj.dump test:{assays:[{name: "mtb", result: :positive}]}, encounter: {patient_age: Cdx::Field::DurationField.years(10)})
        DeviceMessage.create_and_process device: device2, plain_text_data: (Oj.dump test:{assays:[{name: "mtb", result: :negative}]}, encounter: {patient_age: Cdx::Field::DurationField.years(20)})

        refresh_index

        response = get_updates 'institution.id' => institution.id
        expect(response.size).to eq(1)
      end
    end
  end
end
