class ChangeIndexFailureReasonEventsColumnToText < ActiveRecord::Migration
  def change
    change_column :events, :index_failure_reason, :text
  end
end
