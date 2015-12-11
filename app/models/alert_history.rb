class AlertHistory < ActiveRecord::Base
  belongs_to :user
  belongs_to :alert
  belongs_to :test_result
end
 
