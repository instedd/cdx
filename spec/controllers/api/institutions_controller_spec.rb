require 'spec_helper'

describe Api::InstitutionsController do
  let!(:user) { User.make! }
  let!(:institution) { Institution.make! user: user }

  context "with signed in user" do
    before(:each) { sign_in user }

    context "Institutions" do
      it "should list the institution" do
        result = get :index, format: 'json'

        expect(Oj.load(result.body)).to eq({'total_count' => 1, 'institutions' => [
          {'uuid' => institution.uuid, 'name' => institution.name}
        ]})
      end

      it "should list the institutions for given user" do
        other_institution = Institution.make! user: user
        Institution.make! user: User.make!
        result = get :index, format: 'json'
        expect(Oj.load(result.body)).to eq({'total_count' => 2, 'institutions' => [
          {'uuid' => institution.uuid, 'name' => institution.name},
          {'uuid' => other_institution.uuid, 'name' => other_institution.name}
        ]})
      end

      context 'CSV' do
        def check_institutions_csv(r)
          expect(r.status).to eq(200)
          expect(r.content_type).to eq("text/csv")
          expect(r.headers["Content-Disposition"]).to eq("attachment; filename=\"Institutions-#{DateTime.now.strftime('%Y-%m-%d-%H-%M-%S')}.csv\"")
          expect(r).to render_template("api/institutions/index")
        end

        render_views

        before(:each) { Timecop.freeze }

        it "should respond a csv" do
          get :index, format: 'csv'

          check_institutions_csv response
          expect(response.body).to eq("uuid,name\n#{institution.uuid},#{institution.name}\n")
        end
      end
    end
  end

  context "with api token" do
    let!(:token) { user.create_api_token }

    it "should list the institution" do
      result = get :index, access_token: token.token, format: 'json'

      expect(Oj.load(result.body)).to eq({'total_count' => 1, 'institutions' => [
        {'uuid' => institution.uuid, 'name' => institution.name}
      ]})
    end
  end
end
