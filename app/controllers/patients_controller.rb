class PatientsController < ApplicationController
  def index
    @can_create = true # TODO change permission
    # @patients = check_access(Patient.where(institution: @navigation_context.institution).order(updated_at: :desc), READ_INSTITUTION) # TODO change permission
    @patients = Patient.where(institution: @navigation_context.institution).order(updated_at: :desc)
  end

  def new
    @patient = PatientForm.new
    prepare_for_institution_and_authorize(@patient, READ_INSTITUTION) # TODO change permission
  end

  def edit
  end

  def create
    @institution = @navigation_context.institution
    return unless authorize_resource(@institution, READ_INSTITUTION) # TODO change permission

    @patient = PatientForm.new(patient_params)
    @patient.institution = @institution


    if @patient.save
      redirect_to patients_path, notice: 'Patient was successfully created.'
    else
      render action: 'new'
    end
  end

  private

  def patient_params
    params.require(:patient).permit(:name, :dob_text, :lat, :lng, :location_geoid, :address, :email, :phone)
  end
end
