class AddSampleIdResetPolicyToSites < ActiveRecord::Migration
  def change
    add_column :sites, :sample_id_reset_policy, :string, default: "yearly"
  end
end
