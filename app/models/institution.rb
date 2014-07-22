class Institution < ActiveRecord::Base
  include Resource
  belongs_to :user
  has_many :laboratories, dependent: :destroy
  has_many :devices, dependent: :destroy

  def self.filter_by_owner(user)
    where(user_id: user.id)
  end

  def filter_by_owner(user)
    user_id == user.id ? self : nil
  end

  def to_s
    name
  end

  def elasticsearch_index_name
    "#{ElasticsearchHelper.index_prefix}_#{id}"
  end
end
