module EventFiltering
  extend ActiveSupport::Concern

  included do
    def self.query params
      conditions = process_conditions(params)
      # conditions = process_conditions(params[:body], conditions)

      query = and_conditions(conditions)
      order = process_order(params)

      # group_by = params["group_by"] || post_body["group_by"]
      # if group_by do
        # events = EventGrouping.query_with_group_by(query, group_by)
      # else
        events = query_without_group_by(query, order)
      # end

      events
    end

    def self.query_without_group_by query, sort
      client = Elasticsearch::Client.new log: true
      client.search(index: "#{Elasticsearch.index_prefix}*", body: {query: query, sort: sort})["hits"]["hits"].map do |hit|
        hit["_source"]
      end
    end

    def self.process_conditions params, conditions=[]
      conditions = process_fields(Event.searchable_fields, params, conditions)
      if conditions.empty?
        [{match_all: []}]
      else
        conditions
      end
    end

    def self.and_conditions conditions
      return [] if conditions.empty?
      return conditions.first if conditions.size == 1

      {bool: {must: conditions}}
    end

    def self.process_fields fields, params, conditions=[]
      fields.inject conditions do |conditions, field_definition|
        if field_definition[:type] == :nested
          nested_conditions = self.process_fields(field_definition[:sub_fields], params)
          if nested_conditions.empty?
            conditions
          else
            conditions +
            [
              {nested: {
                path: field_definition[:name],
                query: and_conditions(nested_conditions),
              }}
            ]
          end
        else
          field_definition[:parameter_definition].inject conditions do |conditions, parameter_definition|
            process_field(field_definition, parameter_definition, params, conditions)
          end
        end
      end
    end

    def self.process_field field_definition, parameter_definition, params, conditions
      case parameter_definition[:type]
      when :match
        if field_value = params[parameter_definition[:name]]
          conditions + [{match: {field_definition[:name] => field_value}}]
        else
          conditions
        end
      when :range
        if field_value = params[parameter_definition[:name]]
          conditions + [{range: {field_definition[:name] => ({parameter_definition[:boundary] => field_value}.merge parameter_definition[:options])}}]
        else
          conditions
        end
      else
        conditions
      end
    end

    # def process_field {field_name, type, [{param_name, :match}| tail ]}, params, conditions
    #   if field_value = params[param_name] do
    #     condition = [match: [{field_name, field_value}]]
    #     conditions = [condition | conditions]
    #   end
    #   process_field({field_name, type, tail}, params, conditions)
    # end

    # def process_field {field_name, type, [{param_name, :wildcard}| tail ]}, params, conditions
    #   if field_value = params[param_name] do
    #     condition = if Regex.match? ~r/.*\*.*/, field_value do
    #       [wildcard: [{field_name, field_value}]]
    #     else
    #       [match: [{field_matcher(field_name, type), field_value}]]
    #     end
    #     conditions = [condition | conditions]
    #   end
    #   process_field({field_name, type, tail}, params, conditions)
    # end

    # def process_field {field_name, type, [{param_name, {:range, [start | options]}}| tail ]}, params, conditions
    #   if field_value = params[param_name] do
    #     condition = [range: [{field_name, [{start, field_value}] ++ options}]]
    #     conditions = [condition | conditions]
    #   end
    #   process_field({field_name, type, tail}, params, conditions)
    # end

    # def process_field {field_name, :nested, nested_fields}, params, conditions
    #   nested_fields = Enum.map nested_fields, fn({name, type, properties}) ->
    #     {"#{field_name}.#{name}", type, properties}
    #   end
    #   nested_conditions = process_fields(nested_fields, params, [])
    #   case nested_conditions do
    #     [] ->
    #       conditions
    #     _  ->
    #       condition = [
    #         nested: [
    #           path: field_name,
    #           query: and_conditions(nested_conditions),
    #         ]
    #       ]
    #       [condition | conditions]
    #   end
    # end

    # def process_field {_, _, []}, _, conditions
    #   conditions
    # end

    def self.process_order params
      if order = params["order_by"]
        all_orders = order.split ","
        all_orders.map do |order|
          if order[0] == "-"
            {order[1..-1] => "desc"}
          else
            {order => "asc"}
          end
        end
      else
        [{created_at: "asc"}]
      end
    end
  end
end
