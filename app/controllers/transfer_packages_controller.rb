class TransferPackagesController < ApplicationController
  include Concerns::ViewHelper

  helper_method :samples_data
  helper_method :available_institutions

  def new
    @view_helper = view_helper({ save_back_path: true })
    @can_update = true

    @transfer_package = TransferPackage.new(sender_institution: @navigation_context.institution)
  end

  def create
    @transfer_package = TransferPackage.new(transfer_package_params)
    @transfer_package.sender_institution = @navigation_context.institution

    valid = @transfer_package.valid?
    if @transfer_package.sample_transfers.empty?
      @transfer_package.errors.add :sample_transfers, "must not be empty"
      valid = false
    end

    @transfer_package.sample_transfers.each do |sample_transfer|
      sample = sample_transfer.sample
      raise "User not authorized for transferring sample #{sample.uuid}" unless authorize_resource?(sample, UPDATE_SAMPLE)
    end

    if valid && @transfer_package.save
      redirect_to sample_transfers_path, notice: "Samples were succesfully sent"
    else
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
      :receiver_institution_id,
      :recipient,
      :includes_qc_info,
      sample_transfers_attributes: [:sample_id, :_destroy],
    )
  end

  def available_institutions
    Institution.where.not(id: @transfer_package.sender_institution.id)
  end

  def samples_data(samples)
    samples.map { |sample|
      data = {
        id: sample.id,
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
