class AlertConditionResult < ActiveRecord::Base
  belongs_to :alert
  validates_presence_of :result
end
