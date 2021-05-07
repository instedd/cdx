class TestResultParsedDatum < ApplicationRecord
  belongs_to :test_result
  serialize :data, Hash
end
