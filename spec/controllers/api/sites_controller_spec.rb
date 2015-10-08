require 'spec_helper'

describe Api::SitesController do
  let(:user) {User.make}
  let(:institution) {Institution.make user_id: user.id}
  let(:device) {Device.make institution_id: institution.id}
  let(:data) {Oj.dump results: [result: :positive]}
  before(:each) {sign_in user}

  context "Sites" do
    it "should list the sites" do
      institution = Institution.make user: user
      sites = 3.times.map do
        site = Site.make(institution: institution)
        {'uuid' => site.uuid, 'name' => site.name, 'location' => site.location_geoid}
      end

      result = get :index, format: 'json'
      expect(Oj.load(result.body)).to eq({'total_count' => 3, 'sites' => sites})
    end

    it "should list the sites for a given institution" do
      institution = Institution.make user: user
      sites = 3.times.map do
        site = Site.make(institution: institution)
        {'uuid' => site.uuid, 'name' => site.name, 'location' => site.location_geoid}
      end

      Site.make institution: (Institution.make user: user)

      get :index, institution_uuid: institution.uuid, format: 'json'
      expect(Oj.load(response.body)).to eq({'total_count' => 3, 'sites' => sites})
    end

    context 'CSV' do
      def check_sites_csv(r)
        expect(r.status).to eq(200)
        expect(r.content_type).to eq("text/csv")
        expect(r.headers["Content-Disposition"]).to eq("attachment; filename=\"Sites-#{DateTime.now.strftime('%Y-%m-%d-%H-%M-%S')}.csv\"")
        expect(r).to render_template("api/sites/index")
      end

      let(:institution) { Institution.make user: user }
      let(:site) { Site.make(institution: institution) }

      render_views

      before(:each) { Timecop.freeze }

      it "should respond a csv" do
        institution
        site

        get :index, format: 'csv'

        check_sites_csv response
        expect(response.body).to eq("uuid,name,location\n#{site.uuid},#{site.name},#{site.location_geoid}\n")
      end

      it "renders column names even when there are no sites to render" do
        institution

        get :index, format: 'csv'

        check_sites_csv response
        expect(response.body).to eq("uuid,name,location\n")
      end
    end
  end
end
