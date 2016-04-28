class EntityQuery < Cdx::Api::Elasticsearch::Query
  include Policy::Actions

  class << self
    private :new
  end

  def initialize(params, fields, policies)
    super(params, fields)
    @policies = policies
  end

  def process_conditions(*args)
    query = super

    preloaded_uuids = preload_uuids_for(@policies)

    policies_conditions = @policies.map do |policy|
      positive  = super(params_for(policy, preloaded_uuids))
      negatives = policy.exceptions.map do |exception|
        super(params_for(exception, preloaded_uuids))
      end

      if negatives.empty?
        self.class.and_conditions(positive)
      else
        { bool: { must: positive, must_not: negatives } }
      end
    end

    query << self.class.or_conditions(policies_conditions)
    query
  end

  protected

  def params_for(computed_policy, preloaded_uuids)
    Hash[computed_policy.conditions.map do |field, value|
      if field == :site
        # In the case of a site the resource_id is a prefix of all uuids
        ["#{field}.path", value.split('.').last] unless value.nil?
      else
        ["#{field}.uuid", preloaded_uuids[field][value.to_i]] unless value.nil?
      end
    end.compact]
  end

  def preload_uuids_for(policies)
    resource_ids = Hash.new { |h, k| h[k] = Set.new }

    (policies + policies.map(&:exceptions).flatten).each do |policy|
      policy.conditions.each do |field, value|
        resource_ids[field] << value
      end
    end

    Hash[resource_ids.map do |field, ids|
      if field == :site
        # In the case of a site the resource_id is a prefix of all uuids
        [field, ids]
      else
        [field, Hash[field.to_s.classify.constantize.where(id: ids.to_a).pluck(:id, :uuid)]]
      end
    end]
  end
end
