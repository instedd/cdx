class PendingInstitutionInvite < ActiveRecord::Base

  belongs_to :invited_user, :class_name => 'User'
  belongs_to :invited_by_user, :class_name => 'User'

  institution_kinds = %w(institution manufacturer health_organization)

  validates_presence_of :invited_user
  validates_presence_of :invited_by_user
  validates_presence_of :institution_name
  validates_presence_of :institution_kind

  validates_inclusion_of :institution_kind, in: institution_kinds

  def self.user_has_pending_invites?(user)
    where(invited_user_id: user).count > 0
  end

end