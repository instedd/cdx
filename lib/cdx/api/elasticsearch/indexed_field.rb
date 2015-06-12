class Cdx::Api::Elasticsearch::IndexedField
  attr_reader :name, :core_field, :sub_fields, :group_definitions, :filter_definitions
  delegate :scoped_name, :type, :nested?, to: :core_field

  def self.for(core_field, api_fields, document_format)
    definition = api_fields.detect do |definition|
      definition[:name] == core_field.scoped_name
    end
    new(core_field, (definition || {}), document_format)
  end

  def initialize core_field, definition, document_format
    @core_field = core_field

    @name = document_format.indexed_field_name(scoped_name)

    if nested?
      @sub_fields = core_field.sub_fields.map do |field|
        self.class.new(field, document_format)
      end
    else
      if definition[:filter_parameter_definition] != 'none'
        @filter_definitions = if definition[:filter_parameter_definition]
          filters = definition[:filter_parameter_definition]
          filters.each do |filter|
            filter[:name] = scoped_name unless filter[:name]
            filter[:type] = default_filter_type unless filter[:type]
          end
          filters
        else
          default_filter_definition
        end
      else
        definition[:filter_parameter_definition] = Array.new
      end

      if definition[:group_parameter_definition] != 'none'
        @group_definitions = if definition[:group_parameter_definition]
          groups = definition[:group_parameter_definition]
          groups.each do |group|
            group[:name] = scoped_name unless group[:name]
            group[:type] = default_grouping_type unless group[:type]
          end
          groups
        else
          default_group_definition
        end
      else
        definition[:group_parameter_definition] = Array.new
      end
    end
  end

  def self.grouping_detail_for field_name, values=nil, api
    grouping_detail = nil

    api.searchable_fields.detect do |field|
      grouping_detail = field.grouping_detail_for field_name, values
    end

    grouping_detail
  end

  def grouping_detail_for field_name, values=nil
    GroupingDetail.for self, field_name, values
  end

private

  def default_filter_definition
    case type
    when 'date'
      default_date_filter_definition
    else
      [{name: scoped_name, type: default_filter_type}]
    end
  end

  def default_date_filter_definition_boundary(suffix, boundary)
    {name: "#{scoped_name}_#{suffix}", type: 'range', boundary: boundary, options: { include_lower: true }}
  end

  def default_date_filter_definition
    [default_date_filter_definition_boundary('since', 'from'), default_date_filter_definition_boundary('until', 'to')]
  end

  def default_filter_type
    if type == 'integer'
      'match'
    else
      'wildcard'
    end
  end

  def default_group_definition
    if type == 'date'
      [
        {name: "year(#{scoped_name})", type: 'date', interval: 'year'},
        {name: "month(#{scoped_name})", type: 'date', interval: 'month'},
        {name: "week(#{scoped_name})", type: 'date', interval: 'week'},
        {name: "day(#{scoped_name})", type: 'date', interval: 'day'}
      ]
    else
      [{name: scoped_name, type: default_grouping_type}]
    end
  end

  def default_grouping_type
    'flat'
  end
end
