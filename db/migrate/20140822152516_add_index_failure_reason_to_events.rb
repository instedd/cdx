class AddIndexFailureReasonToEvents < ActiveRecord::Migration
  def change
    add_column :events, :index_failure_reason, :string
  end
end
