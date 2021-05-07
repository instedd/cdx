class AlertConditionResult < ApplicationRecord
  belongs_to :alert
  validates_presence_of :result
end
