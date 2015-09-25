class EncountersController < ApplicationController
  before_filter :load_institutions
  before_filter do
    @main_column_width = 6 unless params[:action] == 'index'
  end

  def new
    @encounter = Encounter.new
    return unless prepare_for_institution_and_authorize(@encounter, CREATE_INSTITUTION_ENCOUNTER)
  end

  def create
    @institution = Institution.find params[:encounter][:institution_id]
    return unless authorize_resource(@institution, CREATE_INSTITUTION_ENCOUNTER)

    @encounter = @institution.encounters.new

    if @encounter.save
      redirect_to encounter_path(@encounter), notice: 'Encounter was successfully created.'
    else
      render 'new'
    end
  end

  def show
    # TODO add policy for reading encounters
    # TODO load encounter
  end

  private

  def load_institutions
    @institutions = check_access(Institution, CREATE_INSTITUTION_ENCOUNTER)
  end
end
