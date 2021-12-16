class PendingInstitutionInvite < ActiveRecord::Base

  institution_kinds = %w(institution manufacturer health_organization)

  validates_presence_of :user_id
  validates_presence_of :institution_name
  validates_presence_of :institution_kind

  validates_presence_of :institution_kind
  validates_inclusion_of :institution_kind, in: institution_kinds
end