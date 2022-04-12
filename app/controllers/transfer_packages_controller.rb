class TransferPackagesController < ApplicationController
  def find_sample
    @navigation_context = NavigationContext.new(nil, params[:context])

    uuid = params[:uuid]
    full_uuid = uuid.size == 36
    @samples = Sample
      .within(@navigation_context.entity, @navigation_context.exclude_subsites)
      .joins(:sample_identifiers).where(
        (full_uuid ? "sample_identifiers.uuid = ?" : "sample_identifiers.uuid LIKE concat(?, '%')"),
        uuid
      )
      .order("created_at DESC")
      .limit(5)

    @samples = check_access(@samples, READ_SAMPLE)

    if full_uuid && @samples.any?(&:is_quality_control?)
      render json: { error: "Sample #{uuid} is a QC sample and can't be transferred." }
      return
    end

    render json: { samples: samples_data(@samples) }
  end

  private

  def samples_data(samples)
    samples.map { |sample|
      next if sample.is_quality_control?
      {
        uuid: sample.uuid,
        hasQcReference: sample.has_qc_reference?,
      }
    }.compact
  end
end
