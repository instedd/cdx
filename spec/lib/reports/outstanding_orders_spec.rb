require 'spec_helper'

RSpec.describe Reports::OutstandingOrders, elasticsearch: true do
  let(:current_user) { User.make }
  let(:site_user) { "#{current_user.first_name} #{current_user.last_name}" }
  let(:institution) { Institution.make(user_id: current_user.id) }
  let(:site) { Site.make(institution: institution) }
  let(:device)   { Device.make institution_id: institution.id, site: site }

  let!(:patient)   { Patient.make(institution: institution, core_fields: {"gender" => "male"}, custom_fields: {"custom" => "patient value"}, plain_sensitive_data: {"name": "Doe"}) }
  let!(:encounter) { Encounter.make(institution: institution, patient: patient, start_time: Time.now-2.months, core_fields: {"patient_age" => {"years"=>12}, "diagnosis" =>["name" => "mtb", "condition" => "mtb", "result" => "positive"]}, custom_fields: {"custom" => "encounter value"}, plain_sensitive_data: {"observations": "HIV POS"}) }

  let!(:encounter2) { Encounter.make(institution: institution, patient: patient, start_time: Time.now-2.months, core_fields: {"patient_age" => {"years"=>12}, "diagnosis" =>["name" => "mtb", "condition" => "mtb", "result" => "positive"]}, custom_fields: {"custom" => "encounter value"}, plain_sensitive_data: {"observations": "HIV POS"}) }

  let!(:sample)    { Sample.make(institution: institution, encounter: encounter, patient: patient, core_fields: {"type" => "blood"}, custom_fields: {"custom" => "sample value"}) }
  let!(:sample_id) { sample.sample_identifiers.make }

  let!(:sample2)    { Sample.make(institution: institution, encounter: encounter2, patient: patient, core_fields: {"type" => "blood"}, custom_fields: {"custom" => "sample value"}) }
  let!(:sample_id2) { sample2.sample_identifiers.make }

  let(:nav_context) { NavigationContext.new(current_user, institution.uuid) }

  #   let(:blender) { Blender.new(@institution) }

  before do
    encounter.start_time=DateTime.new(Time.now.year,Time.now.month,Time.now.day,11,11,0).utc.iso8601
    encounter_indexer = EncounterIndexer.new(encounter).index

    encounter2.start_time=DateTime.new(Time.now.year,Time.now.month,Time.now.day,11,11,0).utc.iso8601
    encounter_indexer2 = EncounterIndexer.new(encounter2).index


    test_result  = TestResult.make_from_sample(sample, device: device,
    core_fields: {"name" => "test1", "error_description" => "No error","type" => "specimen",'start_time' => (Time.now - 1.week),'end_time' => Time.now,'reported_time' => Time.now,
      "assays" =>[{"condition" => "mtb", "result" => "positive", "name" => "mtb"},
        {"condition" => "flu", "result" => "negative", "name" => "flu"}]},
        custom_fields: {"custom_a" => "test value 1"}).tap { |t| TestResultIndexer.new(t).index(true) }

        TestResult.make_from_sample(sample2, device: device,
        core_fields: {"name" => "test1", "error_description" => "No error","type" => "specimen",'start_time' => (Time.now - 1.month),'end_time' => Time.now,'reported_time' => Time.now,
          "assays" =>[{"condition" => "mtb", "result" => "positive", "name" => "mtb"},
            {"condition" => "flu", "result" => "negative", "name" => "flu"}]},
            custom_fields: {"custom_a" => "test value 1"}).tap { |t| TestResultIndexer.new(t).index(true) }

            blender = Blender.new(institution)
            blender = blender.load(test_result)
            # Merge new attributes and sample id
            #blender.merge_attributes attributes_for('test').merge(sample_id: sample_id)
            #blender.save_and_index!
            blender.save!
            refresh_index
          end

          describe 'process results and sort by month' do
            before do
              options={}
              options['since'] =nil
              @data = Reports::OutstandingOrders.process(current_user, nav_context, options)
            end

            xit 'returns correct order results' do
              result=@data.latest_encounter
              expect(result.length).to eq(2)
            end

          end
        end
