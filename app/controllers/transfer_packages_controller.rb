class TransferPackagesController < ApplicationController
  include Concerns::ViewHelper

  helper_method :boxes_data
  helper_method :available_institutions

  def new
    @view_helper = view_helper({ save_back_path: true })
    @can_update = true

    @transfer_package = TransferPackage.new(sender_institution: @navigation_context.institution)
  end

  def create
    @transfer_package = TransferPackage.new(transfer_package_params)
    @transfer_package.sender_institution = @navigation_context.institution

    @transfer_package.box_transfers.each do |box_transfer|
      box = box_transfer.box
      raise "User not authorized for transferring box #{box.uuid}" unless authorize_resource?(box, UPDATE_BOX)
    end

    if @transfer_package.save
      redirect_to boxes_path, notice: "Boxes were succesfully sent"
    else
      @view_helper = view_helper
      @can_update = true
      render action: "new"
    end
  end

  def find_box
    @navigation_context = NavigationContext.new(nil, params[:context])

    uuid = params[:uuid]
    full_uuid = uuid.size == 36
    @boxes = Box
      .within(@navigation_context.entity, @navigation_context.exclude_subsites)
      .autocomplete(uuid)
      .order("created_at DESC")
      .count_samples
      .limit(5)

    @boxes = check_access(@boxes, READ_BOX)

    render json: { boxes: boxes_data(@boxes) }
  end

  private

  def transfer_package_params
    params.require(:transfer_package).permit(
      :receiver_institution_id,
      :recipient,
      :includes_qc_info,
      box_transfers_attributes: [:box_id, :_destroy],
    )
  end

  def available_institutions
    Institution.where.not(id: @transfer_package.sender_institution.id)
  end

  def boxes_data(boxes)
    boxes.map { |box|
      {
        id: box.id,
        uuid: box.uuid,
        hasQcReference: box.samples.any?(&:has_qc_reference?),
        preview: render_to_string(partial: "boxes/preview", locals: { box: box }),
      }
    }
  end

  def confirmation_resource(box)
    {
      resource_type: "box",
      resource_id: box.id,
      institution_id: @navigation_context.institution.id,
      site_id: @navigation_context.site.try(&:uuid),
    }
  end
end
