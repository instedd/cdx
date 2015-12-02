class EncountersController < ApplicationController
  before_filter :load_encounter, only: %W(show edit)

  def new
    return unless authorize_resource(@navigation_context.institution, CREATE_INSTITUTION_ENCOUNTER)
  end

  def create
    perform_encounter_action "creating encounter" do
      prepare_encounter_from_json
      @blender.save_and_index!
    end
  end

  def sites
    render json: as_json_site_list(check_access(@navigation_context.institution.sites, READ_SITE)).attributes!
  end

  def show
    return unless authorize_resource(@encounter, READ_ENCOUNTER)
    @can_update = has_access?(@encounter, UPDATE_ENCOUNTER)
  end

  def edit
    return unless authorize_resource(@encounter, UPDATE_ENCOUNTER)
  end

  def update
    perform_encounter_action "updating encounter" do
      prepare_encounter_from_json
      return unless authorize_resource(@encounter, UPDATE_ENCOUNTER)
      raise "encounter.id does not match" if params[:id].to_i != @encounter.id
      @blender.save_and_index!
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

  private

  def perform_encounter_action(action)
    begin
      yield
    rescue Blender::MergeNonPhantomError => e
      render json: { status: :error, message: "Cannot add a test or sample that belongs to a different #{e.entity_type.model_name.singular}", encounter: as_json_edit.attributes! }
    rescue => e
      Rails.logger.error(e.backtrace.unshift(e.message).join("\n"))
      render json: { status: :error, message: "Error #{action} #{e.class}", encounter: as_json_edit.attributes! }
    else
      render json: { status: :ok, encounter: as_json_edit.attributes! }
    end
  end

  def load_encounter
    @encounter = Encounter.where("id = :id OR uuid = :id", params).first
    @institution = @encounter.institution
    @blender = Blender.new(@institution)
    @encounter_blender = @blender.load(@encounter)
    @encounter_as_json = as_json_edit.attributes!
  end

  def institution_by_uuid(uuid)
    check_access(Institution, CREATE_INSTITUTION_ENCOUNTER).where(uuid: uuid).first
  end

  def prepare_encounter_from_json
    encounter_param = @encounter_param = JSON.parse(params[:encounter])
    @encounter = encounter_param['id'] ? Encounter.find(encounter_param['id']) : Encounter.new
    @encounter.is_phantom = false

    if @encounter.new_record?
      @institution = institution_by_uuid(encounter_param['institution']['uuid'])
      @encounter.institution = @institution
      @encounter.site = @institution.sites.where(uuid: encounter_param['site']['uuid']).first
    else
      @institution = @encounter.institution
    end

    @blender = Blender.new(@institution)
    @encounter_blender = @blender.load(@encounter)

    encounter_param['samples'].each do |sample_param|
      add_sample_by_uuids sample_param['uuids']
    end

    encounter_param['test_results'].each do |test_param|
      add_test_result_by_uuid test_param['uuid']
    end

    (encounter_param['assays'] || []).each do |assay|
      qr = assay["quantitative_result"]
      if qr.is_a?(String)
        assay["quantitative_result"] = Integer(qr, 10) rescue nil
      end
    end

    @encounter_blender.merge_attributes(
      'core_fields' => { Encounter::ASSAYS_FIELD => encounter_param['assays'] },
      'plain_sensitive_data' => { Encounter::OBSERVATIONS_FIELD => encounter_param['observations'] }
    )
  end

  def scoped_samples
    Sample.where("samples.id in (#{authorize_resource(TestResult, QUERY_TEST).joins(:sample_identifier).select('sample_identifiers.sample_id').to_sql})")
              .where(institution: @institution)
              .joins(:sample_identifiers)
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

  def merge_samples_by_uuid(uuids)
    samples = scoped_samples.where("sample_identifiers.uuid" => uuids).to_a
    raise ActiveRecord::RecordNotFound if samples.empty?
    target, *to_merge = samples.map{|s| @blender.load(s)}
    @blender.merge_blenders(target, to_merge)
  end

  def scoped_test_results
    authorize_resource(TestResult, QUERY_TEST).where(institution: @institution)
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

  def as_json_edit
    Jbuilder.new do |json|
      json.(@encounter, :id)
      json.assays (@encounter_blender.core_fields[Encounter::ASSAYS_FIELD] || [])
      json.observations @encounter_blender.plain_sensitive_data[Encounter::OBSERVATIONS_FIELD]

      json.institution do
        as_json_institution(json, @institution)
      end

      json.site do
        as_json_site(json, @encounter.site)
      end

      json.patient do
        @encounter_blender.patient.blank? ? json.nil! : json.(@encounter_blender.patient, :plain_sensitive_data, :core_fields)
      end

      json.samples @encounter_blender.samples.uniq do |sample|
        as_json_sample(json, sample)
      end

      json.test_results @encounter_blender.test_results.uniq do |test_result|
        as_json_test_result(json, test_result.single_entity)
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
        as_json_test_result(json, test)
      end
    end
  end

  def as_json_test_result(json, test_result)
    json.(test_result, :uuid, :test_id)
    json.name test_result.core_fields[TestResult::NAME_FIELD]
    if test_result.sample
      json.sample_entity_ids test_result.sample.entity_ids
    end
    json.start_time(format_datetime(test_result.core_fields[TestResult::START_TIME_FIELD]))

    json.assays (test_result.core_fields[TestResult::ASSAYS_FIELD] || [])

    if test_result.device.site
      json.site do
        json.name test_result.device.site.name
      end
    end

    json.device do
      json.name test_result.device.name
    end
  end

  def as_json_institution(json, institution)
    json.(institution, :uuid, :name)
  end

  def as_json_site(json, site)
    json.(site, :uuid, :name)
  end
end
