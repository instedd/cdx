class CreatePendingInstitutionInvites < ActiveRecord::Migration
  def change
    create_table :pending_institution_invites do |t|
      t.string :invited_user_email, index: true
      t.references :invited_by_user, index: true
      t.string :institution_name
      t.string :institution_kind, default: 'institution'
      t.string :status, default: 'pending'
      t.timestamps null: false
    end
  end
end
