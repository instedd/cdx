class EncountersController < ApplicationController
  before_filter :load_institutions

  def new
    @encounter = Encounter.new
    return unless prepare_for_institution_and_authorize(@encounter, CREATE_INSTITUTION_ENCOUNTER)
  end

  def create
    @institution = Institution.find params[:encounter][:institution_id]
    return unless authorize_resource(@institution, CREATE_INSTITUTION_ENCOUNTER)

    @encounter = @institution.encounters.new

    if @encounter.save
      redirect_to edit_encounter_path(@encounter), notice: 'Encounter was successfully created.'
    else
      render 'new'
    end
  end

  def edit
    # TODO add policy for reading encounters
    @encounter = Encounter.find(params[:id])
    @encounter_as_json_edit = as_json_edit(@encounter).attributes!
  end

  def search_sample
    # TODO enforce policy
    # TODO search by entity_id
    samples = Sample.where(["id like ?", "%#{params[:q]}%"])
    render json: as_json_samples_search(samples).attributes!
  end

  def add_sample
    # TODO enforce policy
    encounter = Encounter.find(params[:id])
    sample = Sample.find(params[:sample_id])
    encounter.samples << sample
    encounter.save!

    render json: { status: :ok, encounter: as_json_edit(encounter).attributes! }
  end

  private

  def load_institutions
    @institutions = check_access(Institution, CREATE_INSTITUTION_ENCOUNTER)
  end

  def as_json_edit(encounter)
    Jbuilder.new do |json|
      json.(encounter, :id)
      json.samples encounter.samples do |json, sample|
        as_json_sample(json, sample)
      end
      json.test_results encounter.test_results do |json, test_result|
        as_json_test_result(json, test_result)
      end
    end
  end

  def as_json_samples_search(samples)
    Jbuilder.new do |json|
      json.array! samples do |json, sample|
        as_json_sample(json, sample)
      end
    end
  end

  def as_json_sample(json, sample)
    json.(sample, :id, :entity_id)
    json.institution sample.institution.name
  end

  def as_json_test_result(json, test_result)
    json.(test_result, :id)
    json.name test_result.core_fields[TestResult::NAME_FIELD]
    json.device do
      json.name test_result.device.name
    end
  end
end
