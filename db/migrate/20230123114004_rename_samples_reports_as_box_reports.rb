class RenameSamplesReportsAsBoxReports < ActiveRecord::Migration[5.0]
  def change
    rename_table :samples_reports, :box_reports
    rename_table :samples_report_samples, :box_report_samples
    rename_column :box_report_samples, :samples_report_id, :box_report_id
  end
end
