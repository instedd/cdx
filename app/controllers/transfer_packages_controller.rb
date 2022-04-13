class TransferPackagesController < ApplicationController
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

  def samples_data(samples)
    samples.map { |sample|
      data = {
        uuid: sample.uuid,
        hasQcReference: sample.has_qc_reference?,
      }
      if sample.is_quality_control?
        data[:error] = "Sample #{sample.uuid} is a QC sample and can't be transferred."
      end
      data
    }.compact
  end
end
