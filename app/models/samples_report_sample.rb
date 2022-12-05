class SamplesReportSample < ApplicationRecord
  belongs_to :samples_report
  belongs_to :sample

  def self.entity_scope
    "samples_report_sample"
  end

end