class AddSiteToAlert < ActiveRecord::Migration
  def change
    change_table :alerts do |t|
      t.references :site
    end   
  end
end
