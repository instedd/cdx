class AddFailedToEvents < ActiveRecord::Migration
  def change
    add_column :events, :failed, :boolean
  end
end
