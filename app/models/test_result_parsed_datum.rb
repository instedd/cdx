class TestResultParsedDatum < ActiveRecord::Base
  belongs_to :test_result
  serialize :data, Hash
end
