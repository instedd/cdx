require 'spec_helper'
require 'policy_spec_helper'

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
        {'uuid' => site.uuid, 'name' => site.name, 'location' => site.location_geoid, 'parent_uuid' => site.parent.try(:uuid), 'institution_uuid' => site.institution.uuid}
      end

      new_sorted_sites = sites.sort_by { |f| f['name'] }
      
      result = get :index, format: 'json'
      expect(Oj.load(result.body)).to eq({'total_count' => 3, 'sites' => sites})
    end

    it "should list the sites for a given institution" do
      institution = Institution.make user: user
      sites = 3.times.map do
        site = Site.make(institution: institution)
        {'uuid' => site.uuid, 'name' => site.name, 'location' => site.location_geoid, 'parent_uuid' => site.parent.try(:uuid), 'institution_uuid' => site.institution.uuid}
      end

      Site.make institution: (Institution.make user: user)

      new_sorted_sites = sites.sort_by { |f| f['name'] }
      
      get :index, institution_uuid: institution.uuid, format: 'json'
      expect(Oj.load(response.body)).to eq({'total_count' => 3, 'sites' => sites})
    end

    context "hierarchical" do
      let!(:institution) { Institution.make }
      let!(:root) { Site.make institution: institution }
      let!(:site_a) { Site.make :child, parent: root }
      let!(:site_a_1) { Site.make :child, parent: site_a }
      let!(:site_b) { Site.make :child, parent: root }
      let!(:site_b_1) { Site.make :child, parent: site_b }

      let(:json_response) { Oj.load(response.body) }
      def response_of(site)
        json_response['sites'].detect { |s| s['uuid'] == site.uuid }
      end

      it "should include parent site and parent_uuid" do
        sign_in institution.user

        get :index, format: 'json'
        expect(json_response).to include({'total_count' => 5})
        [root, site_a, site_a_1, site_b, site_b_1].map { |site|
          expect(response_of(site)).to eq({'uuid' => site.uuid, 'name' => site.name, 'location' => site.location_geoid, 'parent_uuid' => site.parent.try(:uuid), 'institution_uuid' => site.institution.uuid})
        }
      end

      it "should hide parent site and parent_uuid if no access" do
        user = User.make
        grant institution.user, user, site_a_1, READ_SITE
        sign_in user

        get :index, format: 'json'
        expect(json_response).to include({'total_count' => 1})
        expect(response_of(site_a_1)).to eq({'uuid' => site_a_1.uuid, 'name' => site_a_1.name, 'location' => site_a_1.location_geoid, 'parent_uuid' => nil, 'institution_uuid' => site_a_1.institution.uuid})
      end

      it "READ_SITE should propagate to the childs" do
        user = User.make
        grant institution.user, user, [site_a, site_b_1], [READ_SITE, READ_SITE]
        sign_in user

        get :index, format: 'json'
        expect(json_response).to include({'total_count' => 3})
        expect(response_of(site_a)).to eq({'uuid' => site_a.uuid, 'name' => site_a.name, 'location' => site_a.location_geoid, 'parent_uuid' => nil, 'institution_uuid' => site_a.institution.uuid})
        expect(response_of(site_a_1)).to eq({'uuid' => site_a_1.uuid, 'name' => site_a_1.name, 'location' => site_a_1.location_geoid, 'parent_uuid' => site_a_1.parent.uuid, 'institution_uuid' => site_a_1.institution.uuid})
        expect(response_of(site_b_1)).to eq({'uuid' => site_b_1.uuid, 'name' => site_b_1.name, 'location' => site_b_1.location_geoid, 'parent_uuid' => nil, 'institution_uuid' => site_b_1.institution.uuid})
      end
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
        expect(response.body).to eq("uuid,name,location,parent_uuid,institution_uuid\n#{site.uuid},#{site.name},#{site.location_geoid},\"#{site.parent.try(:uuid)}\",#{site.institution.uuid}\n")
      end

      it "renders column names even when there are no sites to render" do
        institution

        get :index, format: 'csv'

        check_sites_csv response
        expect(response.body).to eq("uuid,name,location,parent_uuid,institution_uuid\n")
      end
    end
  end
end
