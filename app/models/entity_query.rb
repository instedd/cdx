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
      positive  = super(conditions_for(policy, preloaded_uuids))
      negatives = policy.exceptions.map { |exception| super(conditions_for(exception, preloaded_uuids)) }

      if negatives.empty?
        and_conditions(positive)
      else
        { bool: { must: positive, must_not: negatives } }
      end
    end

    query << or_conditions(policies_conditions)
    query
  end

  def csv_builder
    if grouped_by.empty?
      CSVBuilder.new execute[@fields.result_name]
    else
      CSVBuilder.new execute[@fields.result_name], column_names: grouped_by.concat(["count"])
    end
  end

  protected

  def not_conditions conditions
    return conditions.first if conditions.size == 1
    {bool: {must_not: conditions}}
  end

  def conditions_for(computed_policy, preloaded_uuids)
    Hash[computed_policy.conditions.map do |field, value|
      if field == :site
        # In the case of a site the resource_id is a prefix of all uuids
        ["#{field}.path", value.split(".").last] unless value.nil?
      else
        ["#{field}.uuid", preloaded_uuids[field][value.to_i]] unless value.nil?
      end
    end.compact]
  end

  def preload_uuids_for(policies)
    resource_ids = Hash.new { |h,k| h[k] = Set.new }

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
