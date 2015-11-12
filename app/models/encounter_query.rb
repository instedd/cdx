class EncounterQuery < EntityQuery
  include Policy::Actions

  def self.for params, user
    policies = ComputedPolicy.applicable_policies(READ_ENCOUNTER, Encounter, user).includes(:exceptions)
    if policies.any?
      new params, policies
    else
      Cdx::Api::Elasticsearch::NullQuery.new(params, Cdx::Fields.encounter)
    end
  end

  def initialize(params, policies)
    super(params, Cdx::Fields.encounter, policies)
  end
end
