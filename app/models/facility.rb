class Facility < ActiveRecord::Base
  belongs_to :work_group

  def index_name
    "cdp_facility_#{id}"
  end
end
