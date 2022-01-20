class AddPendingInstitutionInvitesToInstitutions < ActiveRecord::Migration
  def change
    add_column :institutions, :pending_institution_invite_id, :integer
  end
end
