class Role < ApplicationRecord
  include Resource
  include SiteContained

  belongs_to :policy, dependent: :destroy
  has_and_belongs_to_many :users,
    after_add: :update_user_computed_policies,
    after_remove: :update_user_computed_policies

  has_many :alert_recipients

  attr_accessor :definition

  validates_presence_of :name
  validates_presence_of :policy

  scope :predefined, ->{ where.not(key: nil) }

  def update_computed_policies
    users.each do |user|
      user.update_computed_policies
    end
  end

  private

  def update_user_computed_policies(user)
    user.update_computed_policies
  end

end
