class TransferPackagesController < ApplicationController
  include Concerns::ViewHelper

  helper_method :samples_data

  def new
    @view_helper = view_helper({ save_back_path: true })
    @can_update = true

    @transfer_package = TransferPackage.new(sender_institution: @navigation_context.institution)
    @available_institutions = available_institutions
  end

  def create
    params = transfer_package_params
    params.merge!({
      sender_institution: @navigation_context.institution,
    })
    if id = params.delete(:receiver_institution).presence
      params[:receiver_institution] = Institution.find(id)
    end

    samples = Sample
      .within(@navigation_context.institution)
      .find_all_by_any_uuid(params[:sample_transfers_attributes].map { |_, sample_transfer| sample_transfer[:sample_uuid] })

    params[:sample_transfers_attributes].each_value do |sample_transfer_attributes|
      uuid = sample_transfer_attributes.delete(:sample_uuid)

      sample = samples.find { |st| uuid == st.uuid }
      raise ActiveRecord::RecordNotFound unless sample
      raise "Can't transfer QC sample" if sample.is_quality_control?
      raise "User not authorized for transferring sample #{sample.uuid}" unless authorize_resource?(sample, UPDATE_SAMPLE)
      sample_transfer_attributes[:sample] = sample
    end

    @transfer_package = TransferPackage.new(params)

    if @transfer_package.sample_transfers.empty?
      @transfer_package.errors.add :sample_transfers, "Must not be empty"
    end

    if @transfer_package.errors.empty? && @transfer_package.save
      redirect_to sample_transfers_path, notice: "Samples were succesfully sent"
    else
      @available_institutions = available_institutions

      @view_helper = view_helper
      @can_update = true
      render action: "new"
    end
  end

  def find_sample
    @navigation_context = NavigationContext.new(nil, params[:context])

    uuid = params[:uuid]
    full_uuid = uuid.size == 36
    @samples = Sample
      .within(@navigation_context.entity, @navigation_context.exclude_subsites)
      .autocomplete(uuid)
      .order("created_at DESC")
      .limit(5)

    @samples = check_access(@samples, READ_SAMPLE)

    render json: { samples: samples_data(@samples) }
  end

  private

  def transfer_package_params
    params.require(:transfer_package).permit(
      :receiver_institution,
      :recipient,
      :includes_qc_info,
    ).tap do |whitelisted|
      if sample_transfers_attributes = params[:transfer_package][:sample_transfers_attributes]
        sample_transfers_attributes.reject! { |_, attributes| attributes[:sample_uuid].blank? }
        sample_transfers_attributes.transform_values! { |attributes|
          ActionController::Parameters.new(attributes).permit(
            :sample_uuid
          )
        }
        if Rails::VERSION::MAJOR >= 5
          whitelisted[:sample_transfers_attributes] = sample_transfers_attributes.permit!
        else
          whitelisted[:sample_transfers_attributes] = sample_transfers_attributes
        end
      else
        whitelisted[:sample_transfers_attributes] = {}
      end
    end
  end

  def available_institutions
    Institution.where.not(id: @transfer_package.sender_institution.id)
  end

  def samples_data(samples)
    samples.map { |sample|
      data = {
        uuid: sample.uuid,
        hasQcReference: sample.has_qc_reference?,
        preview: render_to_string(partial: "samples/preview", locals: { sample: sample }),
      }
      if sample.is_quality_control?
        data[:error] = "Sample #{sample.uuid} is a QC sample and can't be transferred."
      end
      data
    }.compact
  end

  def confirmation_resource(sample)
    {
      resource_type: "sample",
      resource_id: sample.id,
      institution_id: @navigation_context.institution.id,
      site_id: @navigation_context.site.try(&:uuid),
    }
  end
end
