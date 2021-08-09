class LoincCodesController < ApplicationController
  def search
    @loinc_codes = LoincCode.where("component LIKE concat('%', ?, '%')", params[:q])
    @loinc_codes = @loinc_codes.page(1).per(50)

    builder = Jbuilder.new do |json|
      json.array! @loinc_codes do |loinc_code|
        json.data loinc_code.loinc_number
        json.value "#{loinc_code.id} - #{loinc_code.component}"
        json.id loinc_code.id
      end
    end

    render json: builder.attributes!
  end
end
