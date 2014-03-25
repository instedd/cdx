class Device < ActiveRecord::Base
  belongs_to :work_group

  def index_name
    "cdp_device_#{id}"
  end
end
