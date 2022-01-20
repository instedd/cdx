class PendingInstitutionInvite < ActiveRecord::Base

  belongs_to :invited_by_user, :class_name => 'User'

  institution_kinds = %w(institution manufacturer health_organization)
  statuses = %w(pending accepted)

  validates_presence_of :invited_user_email
  validates_presence_of :invited_by_user
  validates_presence_of :institution_name
  validates_presence_of :institution_kind
  validates_presence_of :status

  validates_inclusion_of :institution_kind, in: institution_kinds
  validates_inclusion_of :status, in: statuses

  def self.user_has_pending_invites?(user)
    where(invited_user_email: user.email,  status: 'pending').count > 0
  end

  def is_pending?
    status == 'pending'
  end

end