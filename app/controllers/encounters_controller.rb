class EncountersController < ApplicationController
  before_filter :load_encounter, only: %W(show edit)

  def new_index
    return unless authorize_resource(Site, CREATE_SITE_ENCOUNTER).empty?
  end

  def new
    if params[:patient_id].present?
      @institution = @navigation_context.institution
      @patient_json = Jbuilder.new do |json|
        scoped_patients.find(params[:patient_id]).as_json_card(json)
      end.attributes!
    end

    @possible_assay_results = TestResult.possible_results_for_assay
    return unless authorize_resource(Site, CREATE_SITE_ENCOUNTER).empty?
  end

  def create
    perform_encounter_action 'creating encounter' do
      prepare_encounter_from_json
      create_new_samples
      @encounter.user = current_user
      @blender.save_and_index!
      @encounter.updated_diagnostic_timestamp!
    end
  end

  def sites
    sites = check_access(@navigation_context.institution.sites, CREATE_SITE_ENCOUNTER)
    render json: as_json_site_list(sites).attributes!
  end

  def show
    return unless authorize_resource(@encounter, READ_ENCOUNTER)
    @can_update = has_access?(@encounter, UPDATE_ENCOUNTER)
  end

  def edit
    if @encounter.has_dirty_diagnostic?
      @encounter.core_fields[Encounter::ASSAYS_FIELD] = @encounter.updated_diagnostic
      prepare_blender_and_json
    end
    @possible_assay_results = TestResult.possible_results_for_assay
    return unless authorize_resource(@encounter, UPDATE_ENCOUNTER)
  end

  def update
    perform_encounter_action "updating encounter" do
      prepare_encounter_from_json
      return unless authorize_resource(@encounter, UPDATE_ENCOUNTER)
      raise "encounter.id does not match" if params[:id].to_i != @encounter.id
      create_new_samples
      @blender.save_and_index!
      @encounter.updated_diagnostic_timestamp!
    end
  end

  def search_sample
    @institution = institution_by_uuid(params[:institution_uuid])
    samples = scoped_samples\
      .joins("LEFT JOIN encounters ON encounters.id = samples.encounter_id")\
      .where("sample_identifiers.entity_id LIKE ?", "%#{params[:q]}%")\
      .where("samples.encounter_id IS NULL OR encounters.is_phantom = TRUE OR sample_identifiers.uuid IN (?)", (params[:sample_uuids] || "").split(','))
    render json: as_json_samples_search(samples).attributes!
  end

  def search_test
    @institution = institution_by_uuid(params[:institution_uuid])
    test_results = scoped_test_results\
      .joins("LEFT JOIN encounters ON encounters.id = test_results.encounter_id")\
      .where("test_results.encounter_id IS NULL OR encounters.is_phantom = TRUE")\
      .where("test_results.test_id LIKE ?", "%#{params[:q]}%")
    render json: as_json_test_results_search(test_results).attributes!
  end

  def add_sample
    perform_encounter_action "adding sample" do
      prepare_encounter_from_json
      add_sample_by_uuid params[:sample_uuid]
      recalculate_diagnostic
    end
  end

  def add_test
    perform_encounter_action "adding test result" do
      prepare_encounter_from_json
      add_test_result_by_uuid params[:test_uuid]
      recalculate_diagnostic
    end
  end

  def merge_samples
    perform_encounter_action "unifying samples" do
      prepare_encounter_from_json
      merge_samples_by_uuid params[:sample_uuids]
      recalculate_diagnostic
    end
  end

  def new_sample
    perform_encounter_action "creating new sample" do
      prepare_encounter_from_json
      added_sample = new_sample_for_site
      @extended_respone = { sample: added_sample }
    end
  end

  def add_sample_manually
    perform_encounter_action "adding manual sample" do
      prepare_encounter_from_json
      sample = { entity_id: params[:entity_id] }
      if validate_manual_sample_non_existant(sample)
        @encounter.new_samples << sample
        @extended_respone = { sample: sample }
      else
        render json: {
          message: "This sample ID has already been used for another patient",
          status: 'error'
        }, status: 200 and return
      end
    end
  end

  private

  def perform_encounter_action(action)
    @extended_respone = {}
    begin
      yield
    rescue Blender::MergeNonPhantomError => e
      render json: { status: :error, message: "Cannot add a test or sample that belongs to a different #{e.entity_type.model_name.singular}", encounter: as_json_edit.attributes! }
    rescue => e
      Rails.logger.error(e.backtrace.unshift(e.message).join("\n"))
      render json: { status: :error, message: "Error #{action} #{e.class}", encounter: as_json_edit.attributes! }
    else
      render json: { status: :ok, encounter: as_json_edit.attributes! }.merge(@extended_respone)
    end
  end

  def load_encounter
    @encounter = Encounter.where('uuid = :id', params).first ||
                 Encounter.where('id = :id', params).first

    return head(:not_found) unless @encounter.present? &&
                                   (@encounter.id == params[:id].to_i ||
                                   @encounter.uuid == params[:id])

    @encounter.new_samples = []
    @institution = @encounter.institution
    prepare_blender_and_json
  end

  def prepare_blender_and_json
    @blender = Blender.new(@institution)
    @encounter_blender = @blender.load(@encounter)
    @encounter_as_json = as_json_edit.attributes!
  end

  def institution_by_uuid(uuid)
    check_access(Institution, READ_INSTITUTION).where(uuid: uuid).first
  end

  def site_by_uuid(institution, uuid)
    check_access(institution.sites, CREATE_SITE_ENCOUNTER).where(uuid: uuid).first
  end

  def prepare_encounter_from_json
    encounter_param = @encounter_param = JSON.parse(params[:encounter])
    @encounter = encounter_param['id'] ? Encounter.find(encounter_param['id']) : Encounter.new
    @encounter.new_samples = []
    @encounter.is_phantom = false

    if @encounter.new_record?
      @institution = institution_by_uuid(encounter_param['institution']['uuid'])
      @encounter.institution = @institution
      @encounter.site = site_by_uuid(@institution, encounter_param['site']['uuid'])
    else
      @institution = @encounter.institution
    end

    @blender = Blender.new(@institution)
    @encounter_blender = @blender.load(@encounter)

    encounter_param['patient'].tap do |patient_param|
      if patient_param.present? && patient_param['id'].present?
        set_patient_by_id patient_param['id']
      end
    end

    encounter_param['samples'].each do |sample_param|
      add_sample_by_uuids sample_param['uuids']
    end

    encounter_param['new_samples'].each do |new_sample_param|
      @encounter.new_samples << {entity_id: new_sample_param['entity_id']}
    end

    encounter_param['test_results'].each do |test_param|
      add_test_result_by_uuid test_param['uuid']
    end

    @encounter_blender.merge_attributes(
      'core_fields' => { Encounter::ASSAYS_FIELD => encounter_param['assays'] },
      'plain_sensitive_data' => { Encounter::OBSERVATIONS_FIELD => encounter_param['observations'] }
    )
  end

  def create_new_samples
    @encounter.new_samples.each do |new_sample|
      add_new_sample_by_entity_id new_sample[:entity_id]
    end
    @encounter.new_samples = []
  end

  def scoped_samples
    samples_in_encounter = "samples.encounter_id = #{@encounter.id} OR " if @encounter.try(:persisted?)
    # TODO this logic is not enough to grab an empty sample from one encounter and move it to another. but is ok for CRUD experience

    Sample.where("#{samples_in_encounter} samples.id in (#{authorize_resource(TestResult, QUERY_TEST).joins(:sample_identifier).select('sample_identifiers.sample_id').to_sql})")
              .where(institution: @institution)
              .joins(:sample_identifiers)
  end

  def new_sample_for_site
    sample = { entity_id: @encounter.site.generate_next_sample_entity_id! }
    @encounter.new_samples << sample
    sample
  end

  def add_sample_by_uuid(uuid)
    sample = scoped_samples.find_by!("sample_identifiers.uuid" => uuid)
    sample_blender = @blender.load(sample)
    @blender.merge_parent(sample_blender, @encounter_blender)
    sample_blender
  end

  def add_sample_by_uuids(uuids)
    sample_blender = merge_samples_by_uuid(uuids)
    @blender.merge_parent(sample_blender, @encounter_blender)
    sample_blender
  end

  def set_patient_by_id(id)
    patient = scoped_patients.find(id)
    patient_blender = @blender.load(patient)
    @blender.merge_parent(@encounter_blender, patient_blender)
    patient_blender
  end

  def add_new_sample_by_entity_id(entity_id)
    sample = Sample.new(institution: @encounter.institution)
    sample.sample_identifiers.build(site: @encounter.site, entity_id: entity_id)

    sample_blender = @blender.load(sample)
    @blender.merge_parent(sample_blender, @encounter_blender)
    sample_blender
  end

  def merge_samples_by_uuid(uuids)
    samples = scoped_samples.where("sample_identifiers.uuid" => uuids).to_a
    raise ActiveRecord::RecordNotFound if samples.empty?
    target, *to_merge = samples.map{|s| @blender.load(s)}
    @blender.merge_blenders(target, to_merge)
  end

  def scoped_test_results
    authorize_resource(TestResult, QUERY_TEST).where(institution: @institution)
  end

  def scoped_patients
    authorize_resource(Patient, READ_PATIENT).where(institution: @institution)
  end

  def add_test_result_by_uuid(uuid)
    test_result = scoped_test_results.find_by!(uuid: uuid)
    test_result_blender = @blender.load(test_result)
    @blender.merge_parent(test_result_blender, @encounter_blender)
    test_result_blender
  end

  def recalculate_diagnostic
    previous_tests_uuids = @encounter_param['test_results'].map{|t| t['uuid']}
    assays_to_merge = @blender.test_results\
      .reject{|tr| (tr.uuids & previous_tests_uuids).any?}\
      .map{|tr| tr.core_fields[TestResult::ASSAYS_FIELD]}

    diagnostic_assays = assays_to_merge.inject(@encounter_param['assays']) do |merged, to_merge|
      Encounter.merge_assays(merged, to_merge)
    end

    @encounter_blender.merge_attributes('core_fields' => {
      Encounter::ASSAYS_FIELD => diagnostic_assays
    })
  end

  def validate_manual_sample_non_existant(sample)
    matching_id = Sample.joins(:sample_identifiers)\
      .where("sample_identifiers.entity_id = ?", "#{sample[:entity_id]}")
    matching_id = matching_id.joins("LEFT JOIN encounters ON encounters.id = samples.encounter_id").where(patient_id: @encounter.patient_id) if @encounter.patient_id
    matching_id.count == 0
  end

  def as_json_edit
    Jbuilder.new do |json|
      json.(@encounter, :id)
      json.(@encounter, :uuid)
      json.has_dirty_diagnostic @encounter.has_dirty_diagnostic?
      json.assays (@encounter_blender.core_fields[Encounter::ASSAYS_FIELD] || [])
      json.observations @encounter_blender.plain_sensitive_data[Encounter::OBSERVATIONS_FIELD]

      json.institution do
        as_json_institution(json, @institution)
      end

      json.site do
        as_json_site(json, @encounter.site)
      end

      json.patient do
        if @encounter_blender.patient.blank?
          json.nil!
        else
          @encounter_blender.patient.preview.as_json_card(json)
        end
      end

      json.samples @encounter_blender.samples.uniq do |sample|
        as_json_sample(json, sample)
      end

      json.(@encounter, :new_samples)

      @localization_helper.devices_by_uuid = @encounter_blender.test_results.map{|tr| tr.single_entity.device}.uniq.index_by &:uuid
      json.test_results @encounter_blender.test_results.uniq do |test_result|
        test_result.single_entity.as_json(json, @localization_helper)
      end
    end
  end

  def as_json_samples_search(samples)
    Jbuilder.new do |json|
      json.array! samples do |sample|
        as_json_sample(json, sample)
      end
    end
  end

  def as_json_site_list(sites)
    Jbuilder.new do |json|
      json.total_count sites.size
      json.sites sites do |site|
        as_json_site(json, site)
      end
    end
  end

  def as_json_sample(json, sample)
    json.(sample, :uuids, :entity_ids)
    json.uuid sample.uuids[0]
  end

  def as_json_test_results_search(test_results)
    Jbuilder.new do |json|
      json.array! test_results do |test|
        test.as_json(json, @localization_helper)
      end
    end
  end

  def as_json_institution(json, institution)
    json.(institution, :uuid, :name)
  end

  def as_json_site(json, site)
    json.(site, :uuid, :name, :allows_manual_entry)
  end
end
