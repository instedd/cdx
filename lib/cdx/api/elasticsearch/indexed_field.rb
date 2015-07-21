class Cdx::Api::Elasticsearch::IndexedField
  attr_reader :name, :core_field, :sub_fields, :group_definitions, :filter_definitions
  delegate :scoped_name, :type, :nested?, :valid_values, to: :core_field

  def self.for(core_field, api_fields, document_format = Cdx::Api::Elasticsearch::CdxDocumentFormat.new)
    definition = api_fields.detect do |definition|
      definition['name'] == core_field.scoped_name
    end
    new(core_field, (definition || {}), document_format)
  end

  def initialize core_field, definition, document_format, already_nested=false
    @core_field = core_field

    @name = if already_nested
      scoped_name
    else
      "test." + scoped_name
    end

    @name = document_format.indexed_field_name(@name)

    if nested?
      @sub_fields = core_field.sub_fields.select(&:has_searchables?).map do |field|
        self.class.new(field, {}, document_format, true)
      end
    else
      initialize_filter_definitions definition
      initialize_group_definitions definition
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
      [{"name" => scoped_name, "type" => default_filter_type}]
    end
  end

  def default_date_filter_definition_boundary(suffix, boundary)
    {"name" => "#{scoped_name}_#{suffix}", "type" => 'range', "boundary" => boundary, "options" => { "include_lower" => true }}
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
        {"name" => "year(#{scoped_name})", "type" => 'date', "interval" => 'year'},
        {"name" => "month(#{scoped_name})", "type" => 'date', "interval" => 'month'},
        {"name" => "week(#{scoped_name})", "type" => 'date', "interval" => 'week'},
        {"name" => "day(#{scoped_name})", "type" => 'date', "interval" => 'day'}
      ]
    else
      [{"name" => scoped_name, "type" => default_grouping_type}]
    end
  end

  def default_grouping_type
    'flat'
  end

  def initialize_filter_definitions(definition)
    @filter_definitions = if definition["filter_parameter_definition"] == 'none'
      Array.new
    else
      if definition["filter_parameter_definition"]
        definition["filter_parameter_definition"].each do |filter|
          filter["name"] ||= scoped_name
          filter["type"] ||= default_filter_type
        end
      else
        default_filter_definition
      end
    end
  end

  def initialize_group_definitions(definition)
    @group_definitions = if definition["group_parameter_definition"] == 'none'
      Array.new
    else
      if definition["group_parameter_definition"]
        definition["group_parameter_definition"].each do |group|
          group["name"] ||= scoped_name
          group["type"] ||= default_grouping_type
        end
      else
        default_group_definition
      end
    end
  end
end
