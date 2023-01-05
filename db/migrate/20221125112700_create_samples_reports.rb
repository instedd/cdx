class CreateSamplesReports < ActiveRecord::Migration
  def up
    create_table :samples_reports do |t|
      t.belongs_to :institution, null: false, index: true
      t.belongs_to :site, index: true
      t.string     :site_prefix, index: true

      t.text       :core_fields
      t.text       :custom_fields
      t.binary     :sensitive_data
      
      t.string :name
      t.float  :threshold

      t.datetime :deleted_at, index: true
      t.timestamps null: false
    end

    add_index :samples_reports, :created_at

    create_table :samples_report_samples do |t|
      t.belongs_to :sample, null: false, index: true
      t.belongs_to :samples_report, null: false, index: true
    end
  end

  def down
    drop_table :samples_reports
    drop_table :samples_report_samples
  end
end
