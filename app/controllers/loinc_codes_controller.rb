class LoincCodesController < ApplicationController
  def search
    @loinc_codes = LoincCode.where("component LIKE concat('%', ?, '%')", params[:q])
    @loinc_codes = @loinc_codes.page(1).per(10)

    builder = Jbuilder.new do |json|
      json.array! @loinc_codes do |loinc_code|
        json.(loinc_code, :id, :loinc_number, :component)
      end
    end

    render json: builder.attributes!
  end
end