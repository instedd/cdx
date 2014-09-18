require 'spec_helper'

describe Api::LaboratoriesController do
  let(:user) {User.make}
  let(:institution) {Institution.make user_id: user.id}
  let(:device) {Device.make institution_id: institution.id}
  let(:data) {Oj.dump results: [result: :positive]}
  before(:each) {sign_in user}

  context "Laboratories" do
    it "should list the laboratories" do
      institution = Institution.make user: user
      lab_ids = 3.times.map do
        lab = Laboratory.make(institution: institution)
        {'id' => lab.id, 'name' => lab.name, 'location' => lab.location_id}
      end

      result = get :index, format: 'json'
      Oj.load(result.body).should eq({'total_count' => 3, 'laboratories' => lab_ids})
    end

    it "should list the laboratories for a given institution" do
      institution = Institution.make user: user
      lab_ids = 3.times.map do
        lab = Laboratory.make(institution: institution)
        {'id' => lab.id, 'name' => lab.name, 'location' => lab.location_id}
      end

      Laboratory.make institution: (Institution.make user: user)

      get :index, institution_id: institution.id, format: 'json'
      Oj.load(response.body).should eq({'total_count' => 3, 'laboratories' => lab_ids})
    end

    context 'CSV' do
      def check_laboratories_csv(r)
        r.status.should eq(200)
        r.content_type.should eq("text/csv")
        r.headers["Content-Disposition"].should eq("attachment; filename=\"Laboratories-#{DateTime.now.strftime('%Y-%m-%d-%H-%M-%S')}.csv\"")
        r.should render_template("api/laboratories/index")
      end

      let(:institution) { Institution.make user: user }
      let(:lab) { Laboratory.make(institution: institution) }

      render_views

      before(:each) { Timecop.freeze }

      it "should respond a csv" do
        institution
        lab

        get :index, format: 'csv'

        check_laboratories_csv response
        response.body.should eq("id,name,location\n#{lab.id},#{lab.name},#{lab.location_id}\n")
      end

      it "renders column names even when there are no laboratories to render" do
        institution

        get :index, format: 'csv'

        check_laboratories_csv response
        response.body.should eq("id,name,location\n")
      end
    end
  end
end
