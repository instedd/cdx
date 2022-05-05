class TransferPackagesController < ApplicationController
  include Concerns::ViewHelper

  helper_method :boxes_data
  helper_method :available_institutions

  def index
    @transfer_packages = TransferPackage
      .within(@navigation_context.institution)
      .includes(:receiver_institution, :sender_institution)
      .order(created_at: :desc)

    @transfer_packages = @transfer_packages.search_uuid(params[:search_uuid])

    case params[:status]
    when "confirmed"
      @transfer_packages = @transfer_packages.where.not(confirmed_at: nil)
    when "in transit"
      @transfer_packages = @transfer_packages.where(confirmed_at: nil)
    else
      params.delete(:status)
    end

    if institution_query = params[:institution].presence
      @transfer_packages = @transfer_packages
        .joins(:receiver_institution, :sender_institution)
        .where("(institutions.name LIKE concat('%', ?, '%') AND institutions.id != ?) OR (sender_institutions_transfer_packages.name LIKE concat('%', ?, '%') AND sender_institutions_transfer_packages.id != ?)", institution_query, @navigation_context.institution.id, institution_query, @navigation_context.institution.id)
    end

    @transfer_packages = perform_pagination(@transfer_packages)
      .map { |transfer| TransferPackagePresenter.new(transfer, @navigation_context) }
  end

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
