class AddDistractorToSamples < ActiveRecord::Migration[5.0]
  def change
    add_column :samples, :distractor, :boolean
  end
end
