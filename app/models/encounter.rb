class Encounter < ActiveRecord::Base
  include Entity
  include AutoUUID
  include AutoIdHash

  has_many :samples, before_add: :add_test_results
  has_many :test_results

  belongs_to :institution
  belongs_to :patient

  validates_presence_of :institution

  def entity_id
    core_fields["id"]
  end

  def self.entity_scope
    "encounter"
  end

  private

  def add_test_results(sample)
    self.test_results << sample.test_results
  end
end
