class AddSiteToEncounters < ActiveRecord::Migration
  def change
    add_reference :encounters, :site, index: true, foreign_key: true
  end
end
