class Device < ActiveRecord::Base
  belongs_to :work_group

  before_create :set_key

  def set_key
    self.secret_key = Guid.new.to_s
  end
end
