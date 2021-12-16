class CreatePendingInstitutionInvites < ActiveRecord::Migration
  def change
    create_table :pending_institution_invites do |t|
      t.belongs_to :user, index: true
      t.string :institution_name
      t.string :institution_kind, default: 'institution'
      t.timestamps null: false
    end
  end
end
