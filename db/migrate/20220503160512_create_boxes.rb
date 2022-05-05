class CreateBoxes < ActiveRecord::Migration
  def change
    create_table :boxes do |t|
      t.string     :uuid, limit: 36, null: false, index: true

      t.belongs_to :institution,     null: false, index: true
      t.belongs_to :site,                         index: true
      t.string     :site_prefix,                  index: true

      t.text       :core_fields
      t.text       :custom_fields
      t.text       :sensitive_data

      t.timestamps null: false
    end

    change_table :samples do |t|
      t.belongs_to :box, null: true, index: true
    end

    change_table :batches do |t|
      t.belongs_to :box, null: true, index: true
    end
  end
end
