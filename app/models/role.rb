class Role < ActiveRecord::Base
  include Resource

  belongs_to :institution
  belongs_to :site
  belongs_to :policy, dependent: :destroy
  has_and_belongs_to_many :users,
    after_add: :update_user_computed_policies,
    after_remove: :update_user_computed_policies

  attr_accessor :definition

  validates_presence_of :name
  validates_presence_of :institution
  validates_presence_of :policy
  validate :validate_site

  scope :predefined, ->{ where.not(key: nil) }

  private

  def validate_site
    if site && site.institution != institution
      errors.add(:site, "must belong to the selected institution")
    end
  end

  def update_user_computed_policies(user)
    user.update_computed_policies
  end
end
