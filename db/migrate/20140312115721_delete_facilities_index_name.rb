class DeleteFacilitiesIndexName < ActiveRecord::Migration
  def change
    remove_column :facilities, :index_name
  end
end
