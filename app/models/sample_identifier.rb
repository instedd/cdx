class SampleIdentifier < ActiveRecord::Base
  include AutoUUID

  belongs_to :sample, inverse_of: :sample_identifiers
  has_many :test_results, inverse_of: :sample_identifier
end
