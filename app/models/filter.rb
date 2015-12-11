class Filter < ActiveRecord::Base
  belongs_to :user
  has_many :subscribers, ->(f) { where user_id: f.user_id }, dependent: :restrict_with_error
  serialize :query, JSON

  validates_presence_of :user
  validates_presence_of :name
  validates_presence_of :query

  after_update :recreate_subscriber_percolators

  def create_query
    TestResult.query(self.query, self.user)
  end

  private

  def recreate_subscriber_percolators
#    binding.pry
    subscribers.each &:create_percolator
  end
end
