class Device < ActiveRecord::Base
  belongs_to :laboratory
  has_many :test_results

  before_create :set_key

  def set_key
    self.secret_key = Guid.new.to_s
  end
end
