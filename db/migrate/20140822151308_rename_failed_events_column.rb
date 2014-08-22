class RenameFailedEventsColumn < ActiveRecord::Migration
  def change
    rename_column :events, :failed, :index_failed
  end
end
