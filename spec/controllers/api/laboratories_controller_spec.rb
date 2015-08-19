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
        {'id' => lab.id, 'name' => lab.name, 'location' => lab.location_geoid}
      end

      result = get :index, format: 'json'
      expect(Oj.load(result.body)).to eq({'total_count' => 3, 'laboratories' => lab_ids})
    end

    it "should list the laboratories for a given institution" do
      institution = Institution.make user: user
      lab_ids = 3.times.map do
        lab = Laboratory.make(institution: institution)
        {'id' => lab.id, 'name' => lab.name, 'location' => lab.location_geoid}
      end

      Laboratory.make institution: (Institution.make user: user)

      get :index, institution_id: institution.id, format: 'json'
      expect(Oj.load(response.body)).to eq({'total_count' => 3, 'laboratories' => lab_ids})
    end

    context 'CSV' do
      def check_laboratories_csv(r)
        expect(r.status).to eq(200)
        expect(r.content_type).to eq("text/csv")
        expect(r.headers["Content-Disposition"]).to eq("attachment; filename=\"Laboratories-#{DateTime.now.strftime('%Y-%m-%d-%H-%M-%S')}.csv\"")
        expect(r).to render_template("api/laboratories/index")
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
        expect(response.body).to eq("id,name,location\n#{lab.id},#{lab.name},#{lab.location_geoid}\n")
      end

      it "renders column names even when there are no laboratories to render" do
        institution

        get :index, format: 'csv'

        check_laboratories_csv response
        expect(response.body).to eq("id,name,location\n")
      end
    end
  end
end
