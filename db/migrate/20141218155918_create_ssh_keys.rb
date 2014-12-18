class CreateSshKeys < ActiveRecord::Migration
  def change
    create_table :ssh_keys do |t|
      t.text :public_key
      t.references :device, index: true

      t.timestamps
    end
  end
end
