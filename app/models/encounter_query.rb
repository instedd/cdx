class EncounterQuery < EntityQuery
  include Policy::Actions

  def self.for(params, user)
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

  def execute
    result = super
    TestResultQuery.add_names_to result['encounters']
    result
  end

  def self.add_names_to(encounters)
    sites = indexed_model encounters, Site, %w(site uuid)

    encounters.each do |encounter|
      encounter['site']['name'] = sites[encounter['site']['uuid']].try(:name) if encounter['site']
    end
  end
end
