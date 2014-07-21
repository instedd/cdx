module EventFiltering
  extend ActiveSupport::Concern

  included do
    def self.query params
      query = and_conditions(process_conditions(params))

      if params[:group_by]
        query_with_group_by(query, params[:group_by])
      else
        Elasticsearch.search_all(query: query, sort: process_order(params))["hits"]["hits"].map do |hit|
          hit["_source"]
        end
      end
    end

  private

    def self.process_conditions params, conditions=[]
      conditions = process_fields(Event.searchable_fields, params, conditions)
      if conditions.empty?
        [{match_all: []}]
      else
        conditions
      end
    end

    def self.and_conditions conditions
      return conditions.first if conditions.size == 1
      {bool: {must: conditions}}
    end

    def self.process_fields fields, params, conditions=[]
      fields.inject conditions do |conditions, field_definition|
        if field_definition[:type] == "nested"
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
          (field_definition[:filter_parameter_definition] || []).inject conditions do |conditions, filter_parameter_definition|
            process_field(field_definition, filter_parameter_definition, params, conditions)
          end
        end
      end
    end

    def self.process_field field_definition, filter_parameter_definition, params, conditions
      case filter_parameter_definition[:type]
      when "match"
        if field_value = params[filter_parameter_definition[:name]]
          conditions += [{match: {field_definition[:name] => field_value}}]
        end
        conditions
      when "range"
        if field_value = params[filter_parameter_definition[:name]]
          conditions += [{range: {field_definition[:name] => ({filter_parameter_definition[:boundary] => field_value}.merge filter_parameter_definition[:options])}}]
        end
        conditions
      when "wildcard"
        if field_value = params[filter_parameter_definition[:name]]
          condition = if /.*\*.*/ =~ field_value
            [{wildcard: {field_definition[:name] => field_value}}]
          else
            [{match: {field_matcher(field_definition[:name], field_definition[:type]) => field_value}}]
          end
          conditions += condition
        end
        conditions
      else
        conditions
      end
    end

    def self.field_matcher(field_name, field_type)
      # if field_type == :multi_field
      #   "#{field_name}.analyzed"
      # else
        field_name
      # end
    end

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
