class Institution < ActiveRecord::Base
  include Resource
  belongs_to :user
  has_many :laboratories, dependent: :destroy
  has_many :devices, dependent: :destroy
  validates_presence_of :name
  after_create :ensure_elasticsearch_index

  def self.filter_by_owner(user, check_conditions)
    if check_conditions
      where(user_id: user.id)
    else
      self
    end
  end

  def filter_by_owner(user, check_conditions)
    user_id == user.id ? self : nil
  end

  def to_s
    name
  end

  def elasticsearch_index_name
    "#{Cdx::Api.index_prefix}_#{id}"
  end

  def ensure_elasticsearch_index
    Cdx::Api.client.indices.create index: elasticsearch_index_name
  rescue Exception => ex
    binding.pry
    # If index already exists, do nothing
  end
end
