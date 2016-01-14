class PatientsController < ApplicationController
  def index
    @can_create = has_access?(@navigation_context.institution, CREATE_INSTITUTION_PATIENT)
    @patients = check_access(Patient.where(institution: @navigation_context.institution), READ_PATIENT).order(updated_at: :desc)

    if @navigation_context.site
      @patients = @patients.where("id in (#{Encounter.within(@navigation_context.site).select(:patient_id).to_sql})")
    end

    @patients = @patients.where("name LIKE concat('%', ?, '%')", params[:name]) unless params[:name].blank?
    @patients = @patients.where("entity_id LIKE concat('%', ?, '%')", params[:entity_id]) unless params[:entity_id].blank?
    # location_geoid is hierarchical so a prefix search works
    @patients = @patients.where("location_geoid LIKE concat(?, '%')", params[:location]) unless params[:location].blank?

    unless params[:last_encounter].blank?
      date_pattern = I18n.t('date.input_format.pattern')
      @last_encounter = Time.strptime(params[:last_encounter], date_pattern) rescue nil
      params[:last_encounter] = @last_encounter.strftime(date_pattern) rescue nil
      @patients = @patients.where("id in (#{Encounter.within(@navigation_context.entity).where("start_time > ?", @last_encounter).select(:patient_id).to_sql})")
    end

    @patients.preload_locations!

    @page_size = (params["page_size"] || 10).to_i
    @page = (params["page"] || 1).to_i
    @patients = @patients.page(@page).per(@page_size)
    @total = @patients.total_count
  end

  def show
    @patient = Patient.find(params[:id])
    return unless authorize_resource(@patient, READ_PATIENT)
    @can_edit = has_access?(@patient, UPDATE_PATIENT)
  end

  def new
    @patient = PatientForm.new
    prepare_for_institution_and_authorize(@patient, CREATE_INSTITUTION_PATIENT)
  end

  def create
    @institution = @navigation_context.institution
    return unless authorize_resource(@institution, CREATE_INSTITUTION_PATIENT)

    @patient = PatientForm.new(patient_params)
    @patient.institution = @institution

    if @patient.save
      redirect_to patient_path(@patient), notice: 'Patient was successfully created.'
    else
      render action: 'new'
    end
  end

  def edit
    patient = Patient.find(params[:id])
    @patient = PatientForm.edit(patient)
    return unless authorize_resource(patient, UPDATE_PATIENT)

    @can_delete = has_access?(patient, DELETE_PATIENT)
  end

  def update
    patient = Patient.find(params[:id])
    @patient = PatientForm.edit(patient)
    return unless authorize_resource(patient, UPDATE_PATIENT)

    if @patient.update(patient_params)
      redirect_to patient_path(@patient), notice: 'Patient was successfully updated.'
    else
      render action: 'edit'
    end
  end

  def destroy
    @patient = Patient.find(params[:id])
    return unless authorize_resource(@patient, DELETE_PATIENT)

    @patient.destroy

    redirect_to patients_path, notice: 'Patient was successfully deleted.'
  end

  private

  def patient_params
    params.require(:patient).permit(:name, :gender, :dob, :lat, :lng, :location_geoid, :address, :email, :phone)
  end
end
