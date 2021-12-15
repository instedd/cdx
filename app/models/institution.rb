class Institution < ActiveRecord::Base
  include AutoUUID
  include Resource

  KINDS = %w(institution manufacturer health_organization)

  belongs_to :user

  has_many :sites, dependent: :restrict_with_error
  has_many :devices, dependent: :restrict_with_error
  has_many :device_models, dependent: :restrict_with_error, inverse_of: :institution

  has_many :encounters, dependent: :destroy
  has_many :patients, dependent: :destroy
  has_many :samples, dependent: :destroy
  has_many :batches, dependent: :destroy
  has_many :test_results, dependent: :destroy
  has_many :roles, dependent: :destroy
  has_many :alerts

  validates_presence_of :name
  validates_presence_of :kind
  validates_inclusion_of :kind, in: KINDS

  after_create :create_predefined_roles
  after_update :update_predefined_roles, if: :name_changed?

  after_create :update_owner_policies
  after_destroy :update_owner_policies

  def self.filter_by_owner(user, check_conditions)
    if check_conditions
      where(user_id: user.id)
    else
      self
    end
  end

  def self.kinds
    hash = {}
    KINDS.map { |kind| {value: kind, label: kind} }
  end

  def filter_by_owner(user, check_conditions)
    user_id == user.id ? self : nil
  end

  def to_s
    name
  end

  KINDS.each do |kind|
    define_method "kind_#{kind}?" do
      self.kind.try(:to_s) == kind
    end
  end

  private

  def create_predefined_roles
    roles = Policy.predefined_institution_roles(self)
    roles.each do |role|
      role.institution = self
      role.save!
    end
  end

  def update_predefined_roles
    existing_roles = roles.predefined.where(site_id: nil).all
    new_roles = Policy.predefined_institution_roles(self)
    existing_roles.each do |existing_role|
      new_role = new_roles.find { |new_role| new_role.key == existing_role.key }
      next unless new_role

      existing_role.name = new_role.name
      existing_role.save!
    end
  end

  def update_owner_policies
    self.user.try(:update_computed_policies)
  end

end
