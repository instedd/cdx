require 'spec_helper'
require 'policy_spec_helper'

RSpec.describe BoxesController, type: :controller do
  setup_fixtures do
    @user = User.make!

    @institution = Institution.make! user: @user
    @box = Box.make! institution: @institution

    @site = Site.make! institution: @institution
    @site_box = Box.make! institution: @institution, site: @site

    @other_institution = Institution.make!
    @other_user = @other_institution.user

    @confirmed_transfer = TransferPackage.make! :receiver_confirmed, sender_institution: @institution, receiver_institution: @other_institution
    @confirmed_box = @confirmed_transfer.box_transfers[0].box

    grant @user, @other_user, @institution, READ_INSTITUTION
  end

  let(:default_params) do
    { context: institution.uuid }
  end

  before(:each) { sign_in user }

  describe "index" do
    it "should be accessible by institution owner" do
      get :index
      expect(response).to have_http_status(:ok)
      expect(assigns(:boxes).count).to eq(2)
    end

    it "should not list boxes if can not read" do
      sign_in other_user

      get :index
      expect(assigns(:boxes).count).to eq(0)
    end

    describe "filters" do
      before(:each) do
        Box.make!(3, :filled, institution: @institution, purpose: "LOD")
        Box.make!(2, :filled, institution: @institution, purpose: "Variants")
        Box.make!(4, :filled, institution: @institution, purpose: "Challenge")
        Box.make!(1, :filled, institution: @institution, purpose: "Other")
      end

      it "paginates" do
        get :index
        expect(assigns(:boxes).count).to eq(10)
      end

      it "by site" do
        get :index, params: { context: "#{site.uuid}-*" }
        expect(response).to have_http_status(:ok)
        expect(assigns(:boxes).count).to eq(1)
      end

      it "by site excluding subsites" do
        get :index, params: { context: "#{site.uuid}-!" }
        expect(response).to have_http_status(:ok)
        expect(assigns(:boxes).count).to eq(1)
      end

      it "by uuid" do
        get :index, params: { uuid: @box.uuid[0..6] }
        expect(assigns(:boxes).count).to eq(1)
      end

      it "by purpose" do
        get :index, params: { purpose: "LOD" }
        expect(assigns(:boxes).count).to eq(5)

        get :index, params: { purpose: "Variants" }
        expect(assigns(:boxes).count).to eq(2)

        get :index, params: { purpose: "Challenge" }
        expect(assigns(:boxes).count).to eq(4)

        get :index, params: { purpose: "Other" }
        expect(assigns(:boxes).count).to eq(1)
      end
    end
  end

  describe "show" do
    it "should be accessible to institution owner" do
      get :show, params: { id: box.id }
      expect(response).to have_http_status(:ok)
    end

    it "should be allowed if can read" do
      grant user, other_user, box, READ_BOX
      sign_in other_user

      get :show, params: { id: box.id }
      expect(response).to have_http_status(:ok)
    end

    it "shouldn't be allowed if can't read" do
      sign_in other_user

      get :show, params: { id: box.id }
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "blind" do
    it "before transfer: owner institution can blind box" do
      post :blind, params: { id: box.id }
      expect(response).to have_http_status(:found)
    end

    it "after transfer: owner institution can't blind box" do
      sign_in other_user
      post :blind, params: { id: confirmed_box.id, context: other_institution.uuid }
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "unblind" do
    it "before transfer: owner institution can unblind box" do
      post :unblind, params: { id: box.id }
      expect(response).to have_http_status(:found)
    end

    it "after tranfer: owner institution can't unblind box" do
      sign_in other_user
      post :blind, params: { id: confirmed_box.id, context: other_institution.uuid }
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "print" do
    before do
      stub_request(:get, %r{https://fonts\.googleapis\.com/.*}).to_return(body: "")
    end

    it "should be accessible to institution owner" do
      get :print, params: { id: box.id }
      expect(response).to have_http_status(:ok)
    end

    it "should be allowed if can read" do
      grant user, other_user, box, READ_BOX
      sign_in other_user

      get :print, params: { id: box.id }
      expect(response).to have_http_status(:ok)
    end

    it "shouldn't be allowed if can't read" do
      sign_in other_user

      get :print, params: { id: box.id }
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "inventory" do
    it "should be accessible to institution owner" do
      get :inventory, params: { id: box.id, format: "csv" }
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq("text/csv")
      expect(response.body.strip.split("\n").size).to eq(box.samples.count + 1)
      expect(response.body).to_not match("Blinded")
      expect(response.headers["Content-Disposition"]).to match(/cdx_box_inventory_#{box.uuid}\.csv/)
    end

    it "should be ordered by batch_number, concentration, replicate ASC" do
      get :inventory, params: { id: box.id, format: "csv" }
      expect(response).to have_http_status(:ok)
      results = CSV.parse(response.body).tap(&:shift).map do |row|
        { :batch_number => row[3], :concentration => row[6], :replicate => row[7] }
      end
      expect( results ).to eq( results.sort_by{ |sample|  [ sample.batch_number , sample.concentration, sample.replicate ] } )
    end

    it "should be allowed if can read" do
      grant user, other_user, box, READ_BOX
      sign_in other_user

      get :inventory, params: { id: box.id, format: "csv" }
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq("text/csv")
    end

    it "shouldn't be allowed if can't read" do
      sign_in other_user
      get :inventory, params: { id: box.id, format: "csv" }
      expect(response).to have_http_status(:forbidden)
    end

    it "blinds columns for Samples" do
      box = Box.make! :filled_without_measurements, institution: institution, blinded: true

      get :inventory, params: { id: box.id, format: "csv" }
      expect(response).to have_http_status(:ok)

      CSV.parse(response.body).tap(&:shift).each do |row|
        expect(row[3]).to eq("Blinded")
        expect(row[4]).to eq("Blinded")
        expect(row[5]).to eq("Blinded")
        expect(row[6]).to eq("Blinded")
      end
    end

    it "don't blind columns columns for samples with uploaded measurements" do
      box = Box.make! :filled, institution: institution, blinded: true

      get :inventory, params: { id: box.id, format: "csv" }
      expect(response).to have_http_status(:ok)

      CSV.parse(response.body).tap(&:shift).each do |row|
        expect(row[3]).not_to eq("Blinded")
        expect(row[4]).not_to eq("Blinded")
        expect(row[5]).not_to eq("Blinded")
        expect(row[6]).not_to eq("Blinded")
      end
    end

    it "don't blind columns for unblinded inventory" do
      box = Box.make! :filled, institution: institution, blinded: true

      get :inventory, params: { id: box.id, format: "csv", unblind: true }
      expect(response).to have_http_status(:ok)

      CSV.parse(response.body).tap(&:shift).each do |row|
        expect(row[3]).not_to eq("Blinded")
        expect(row[4]).not_to eq("Blinded")
        expect(row[5]).not_to eq("Blinded")
        expect(row[6]).not_to eq("Blinded")
      end
    end

  end

  describe "new" do
    it "should be accessible to institution owner" do
      get :new
      expect(response).to have_http_status(:ok)
    end

    it "should be allowed if can create" do
      grant user, other_user, institution, CREATE_INSTITUTION_BOX
      sign_in other_user

      get :new
      expect(response).to have_http_status(:ok)
    end

    it "shouldn't be allowed if can't create" do
      sign_in other_user

      get :new
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe "validate (CSV)" do
    let!(:batch) do
      Batch.make!(institution: institution, site: site, batch_number: "DISTRACTOR")
    end

    it "validates CSV headers" do
      csv_file = fixture_file_upload(Rails.root.join("spec/fixtures/csvs/samples_results_1.csv"), "text/csv")

      expect do
        post :validate, params: { csv_box: csv_file }, format: "json"
        expect(response).to have_http_status(:ok)
      end.to change(institution.boxes, :count).by(0)

      expect(JSON.parse(response.body)).to eq({
        "found_batches" => [],
        "not_found_batches" => [],
        "samples_count" => 0,
        "error_message" => "Invalid columns"
      })
    end

    it "finds all batches" do
      csv_file = fixture_file_upload(Rails.root.join("spec/fixtures/csvs/csv_box_1.csv"), "text/csv")

      expect do
        post :validate, params: { csv_box: csv_file }, format: "json"
        expect(response).to have_http_status(:ok)
      end.to change(institution.boxes, :count).by(0)

      expect(JSON.parse(response.body)).to eq({
        "found_batches" => ["DISTRACTOR"],
        "not_found_batches" => [],
        "samples_count" => 3,
      })
    end

    it "fails to find some batches" do
      csv_file = fixture_file_upload(Rails.root.join("spec/fixtures/csvs/csv_box_2.csv"), "text/csv")

      expect do
        post :validate, params: { csv_box: csv_file }, format: "json"
        expect(response).to have_http_status(:ok)
      end.to change(institution.boxes, :count).by(0)

      expect(JSON.parse(response.body)).to eq({
        "found_batches" => ["DISTRACTOR"],
        "not_found_batches" => ["VIRUS"],
        "samples_count" => 5,
      })
    end
  end

  describe "create" do
    let :batch do
      Batch.make!(institution: institution, site: site)
    end

    let :box_plan do
      {
        purpose: "LOD",
        option: "add_batches",
        batches: {
          "0" => {
            batch_uuid: batch.uuid,
            concentrations: { "0" => { replicate: "1", concentration: "10" } },
          },
        },
        blinded: false,
      }
    end

    it "should create box in context institution" do
      expect do
        post :create, params: { box: box_plan }
        expect(response).to redirect_to boxes_path
      end.to change(institution.boxes, :count).by(1)

      box = assigns(:box_form).box.reload
      expect(box.uuid).to_not be_nil
      expect(box.institution_id).to eq institution.id
    end

    it "should create box in context site" do
      default_params[:context] = site.uuid

      expect do
        post :create, params: { box: box_plan }
        expect(response).to redirect_to boxes_path
      end.to change(site.boxes, :count).by(1)

      box = assigns(:box_form).box.reload
      expect(box.uuid).to_not be_nil
      expect(box.institution_id).to eq institution.id
      expect(box.site_id).to eq site.id
    end

    it "should create box with optional params" do
      expect do
        post :create, params: { box: box_plan.merge(media: "Saliva", blinded: true) }
        expect(response).to redirect_to boxes_path
      end.to change(institution.boxes, :count).by(1)

      box = assigns(:box_form).box.reload
      expect(box.samples.map(&:media).uniq).to eq(["Saliva"])
      expect(box.blinded).to eq true
    end

    it "should create box if allowed" do
      grant user, other_user, institution, CREATE_INSTITUTION_BOX
      grant user, other_user, batch, READ_BATCH
      sign_in other_user

      expect do
        post :create, params: { box: box_plan }
        expect(response).to redirect_to boxes_path
      end.to change(institution.boxes, :count).by(1)
    end

    it "should not create box if not allowed" do
      sign_in other_user

      expect do
        post :create, params: { box: box_plan }
        expect(response).to have_http_status(:forbidden)
      end.to change(institution.boxes, :count).by(0)
    end

    def expect_samples(batch, concentrations: [1], replicates:)
      # NOTE: can't where/order in SQL because entity fields...
      concentrations.each do |c|
        samples = batch.samples.to_a
          .reject { |s| s.concentration != c }
          .sort_by(&:replicate)

        1.upto(replicates) do |r|
          expect(sample = samples.shift).to_not be_nil
          expect(sample.concentration).to eq(c)
          expect(sample.replicate).to eq(r)
        end
      end
    end

    describe "creates samples from batches" do
      let :virus_batch do
        Batch.make!(institution: institution, site: site)
      end

      let :distractor_batch do
        Batch.make!(institution: institution, site: site)
      end

      let :box_plan do
        {
          purpose: "LOD",
          blinded: true,
        }
      end

      it "creates samples with proper replicate and concentration from virus and distractor batches" do
        batches = {
          "0" => {
            batch_uuid: virus_batch.uuid,
            distractor: false,
            instruction: "",
            concentrations: {
              "0" => { concentration: "1", replicate: "2" },
            }
          },
          "1" => {
            batch_uuid: distractor_batch.uuid,
            distractor: true,
            instruction: "",
            concentrations: {
              "0" => { concentration: "3e4", replicate: "3" },
              "1" => { concentration: "4e5", replicate: "2" },
            }
          }
        }
        expect do
          post :create, params: { box: box_plan.merge(option: "add_batches", batches: batches) }
          expect(response).to redirect_to boxes_path
        end.to change(institution.boxes, :count).by(1)

        box = assigns(:box_form).box.reload
        expect(box.samples.count).to eq(7)
        expect(box.samples.where(batch: virus_batch).count).to eq(2)
        expect(box.samples.where(batch: virus_batch).map(&:distractor).uniq).to eq([false])
        expect(box.samples.where(batch: virus_batch).map(&:concentration).uniq).to eq([1])
        expect(box.samples.where(batch: distractor_batch).count).to eq(5)
        expect(box.samples.where(batch: distractor_batch).map(&:distractor).uniq).to eq([true])
        expect(box.samples.where(batch: distractor_batch).map(&:concentration).uniq.sort).to eq([30000,400000])
      end
    end

    describe "with existing samples" do
      it "creates with samples" do
        samples = Sample.make! 2, :filled, institution: institution, specimen_role: "b"

        post :create, params: { box: box_plan.merge(
                                    media: "Saliva",
                                    blinded: true,
                                    option: "add_samples",
                                    sample_uuids: { "sample_0" => samples[0].uuid, "sample_1" => samples[1].uuid } ) }

        expect(Box.last.samples.map(&:uuid).sort).to eq(samples.map(&:uuid).sort)
      end

      it "won't create with QC samples" do
        samples = [
          Sample.make!(:filled, institution: institution, specimen_role: "b"),
          Sample.make!(:filled, institution: institution, specimen_role: "q"),
        ]

        expect do
          expect do
            post :create, params: { box: box_plan.merge(
                                    media: "Saliva",
                                    blinded: true,
                                    option: "add_samples",
                                    sample_uuids: { "sample_0" => samples[0].uuid, "sample_1" => samples[1].uuid } ) }
            expect(response).to have_http_status(:unprocessable_entity)
          end.to change(institution.samples, :count).by(0)
        end.to change(institution.boxes, :count).by(0)
      end

      it "requires at least 1 sample" do
        expect do
          expect do
            post :create, params: { box: { purpose: "Other", option: "add_samples", sample_uuids: {}, blinded: false } }
            expect(response).to have_http_status(:unprocessable_entity)
          end.to change(institution.samples, :count).by(0)
        end.to change(institution.boxes, :count).by(0)
      end
    end

    describe "from csv file" do
      it "create box from csv file" do
        Batch.make!(institution: institution, site: site, batch_number: "DISTRACTOR")
        file_path = File.join(Rails.root, 'spec', 'fixtures', 'csvs', 'csv_box_1.csv')
        file = fixture_file_upload(file_path, 'text/csv')
        expect do
          post :create, params: { box: { purpose: "LOD",
                                       media: "Saliva",
                                       option: "add_csv",
                                       csv_box: file,
                                       blinded: false } }

          expect(response).to redirect_to boxes_path
        end.to change(institution.boxes, :count).by(1)
        expect(Box.last.samples.count).to eq(4)
      end

      it "don't create box if invalid csv file" do
        file_path = File.join(Rails.root, 'spec', 'fixtures', 'csvs', 'samples_results_1.csv')
        file = fixture_file_upload(file_path, 'text/csv')
        expect do
          post :create, params: { box: { purpose: "LOD",
                                       media: "Saliva",
                                       option: "add_csv",
                                       csv_box: file,
                                       blinded: false } }

          expect(response).to have_http_status(:unprocessable_entity)
        end.to change(institution.boxes, :count).by(0)
      end

      it "create Challenge box if distractors and virus samples are present" do
        Batch.make!(institution: institution, site: site, batch_number: "VIRUS")
        Batch.make!(institution: institution, site: site, batch_number: "DISTRACTOR")
        file_path = File.join(Rails.root, 'spec', 'fixtures', 'csvs', 'csv_box_2.csv')
        file = fixture_file_upload(file_path, 'text/csv')
        expect do
          post :create, params: { box: { purpose: "Challenge",
                                       media: "Saliva",
                                       option: "add_csv",
                                       csv_box: file,
                                       blinded: false } }
        end.to change(institution.boxes, :count).by(1)
        expect(Box.last.samples.count).to eq(6)
      end

      it "don't create Challenge box if no distractors are present" do
        Batch.make!(institution: institution, site: site, batch_number: "DISTRACTOR")
        file_path = File.join(Rails.root, 'spec', 'fixtures', 'csvs', 'csv_box_1.csv')
        file = fixture_file_upload(file_path, 'text/csv')
        expect do
          post :create, params: { box: { purpose: "Challenge",
                                       media: "Saliva",
                                       option: "add_csv",
                                       csv_box: file,
                                       blinded: false } }

          expect(response).to have_http_status(:unprocessable_entity)
        end.to change(institution.boxes, :count).by(0)
      end

      it "create Variants box if samples from two batches are present" do
        Batch.make!(institution: institution, site: site, batch_number: "VIRUS")
        Batch.make!(institution: institution, site: site, batch_number: "DISTRACTOR")
        file_path = File.join(Rails.root, 'spec', 'fixtures', 'csvs', 'csv_box_2.csv')
        file = fixture_file_upload(file_path, 'text/csv')
        expect do
          post :create, params: { box: { purpose: "Variants",
                                       media: "Saliva",
                                       option: "add_csv",
                                       csv_box: file,
                                       blinded: false } }
        end.to change(institution.boxes, :count).by(1)
        expect(Box.last.samples.count).to eq(6)
      end

      it "don't create Variants box if samples from two batches aren't present" do
        Batch.make!(institution: institution, site: site, batch_number: "DISTRACTOR")
        file_path = File.join(Rails.root, 'spec', 'fixtures', 'csvs', 'csv_box_1.csv')
        file = fixture_file_upload(file_path, 'text/csv')
        expect do
          post :create, params: { box: { purpose: "Variants",
                                       media: "Saliva",
                                       option: "add_csv",
                                       csv_box: file,
                                       blinded: false } }

          expect(response).to have_http_status(:unprocessable_entity)
        end.to change(institution.boxes, :count).by(0)
      end
    end
  end

  describe "destroy" do
    it "should delete box" do
      expect do
        delete :destroy, params: { id: box.id }
        expect(response).to redirect_to boxes_path
      end.to change(institution.boxes, :count).by(-1)
    end

    it "should delete box if allowed" do
      grant user, other_user, box, DELETE_BOX
      sign_in other_user

      expect do
        delete :destroy, params: { id: box.id }
        expect(response).to redirect_to boxes_path
      end.to change(institution.boxes, :count).by(-1)

      expect(box.reload.deleted_at).to_not be_nil
    end

    it "should not delete box if not allowed" do
      sign_in other_user

      expect do
        delete :destroy, params: { id: box.id }
        expect(response).to have_http_status(:forbidden)
      end.to change(institution.boxes.unscoped, :count).by(0)
    end
  end

  describe "bulk_destroy" do
    it "should delete boxes" do
      expect do
        post :bulk_destroy, params: { box_ids: [box.id, site_box.id] }
        expect(response).to redirect_to boxes_path
      end.to change(institution.boxes, :count).by(-2)

      expect(box.reload.deleted_at).to_not be_nil
      expect(site_box.reload.deleted_at).to_not be_nil
    end

    it "should delete boxes if allowed" do
      grant user, other_user, box, DELETE_BOX
      grant user, other_user, site_box, DELETE_BOX
      sign_in other_user

      expect do
        post :bulk_destroy, params: { box_ids: [box.id, site_box.id] }
        expect(response).to redirect_to boxes_path
      end.to change(institution.boxes, :count).by(-2)

      expect(box.reload.deleted_at).to_not be_nil
      expect(site_box.reload.deleted_at).to_not be_nil
    end

    it "should not delete boxes if not all allowed" do
      grant user, other_user, box, DELETE_BOX
      sign_in other_user

      expect do
        post :bulk_destroy, params: { box_ids: [box.id, site_box.id] }
        expect(response).to have_http_status(:forbidden)
      end.to change(institution.boxes, :count).by(0)
    end

    it "should not delete boxes if not allowed" do
      sign_in other_user

      expect do
        post :bulk_destroy, params: { box_ids: [box.id, site_box.id] }
        expect(response).to have_http_status(:forbidden)
      end.to change(institution.boxes.unscoped, :count).by(0)
    end
  end
end
