class LoincCodesController < ApplicationController
  def search
    @loinc_codes = LoincCode.where("component LIKE concat('%', ?, '%') OR loinc_number LIKE concat('%', ?, '%')", params[:q], params[:q])
    @loinc_codes = @loinc_codes.page(1).per(50)

    builder = Jbuilder.new do |json|
      json.array! @loinc_codes do |loinc_code|
        json.data loinc_code.loinc_number
        json.value loinc_code.description
        json.id loinc_code.id
      end
    end

    render json: builder.attributes!
  end
end
