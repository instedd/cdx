class BoxReportSample < ApplicationRecord
  belongs_to :box_report
  belongs_to :sample

  def self.entity_scope
    "box_report_sample"
  end

end