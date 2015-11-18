class SampleIdentifier < ActiveRecord::Base
  include AutoUUID

  belongs_to :sample, inverse_of: :sample_identifiers
  belongs_to :site, inverse_of: :sample_identifiers
  has_many :test_results, inverse_of: :sample_identifier, dependent: :restrict_with_error

  acts_as_paranoid

  def phantom?
    entity_id.nil?
  end

  def not_phantom?
    not phantom?
  end
end
