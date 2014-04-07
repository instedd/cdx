class TestResult < ActiveRecord::Base
  belongs_to :device
  belongs_to :institution
end
