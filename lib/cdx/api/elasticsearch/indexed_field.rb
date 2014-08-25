class Cdx::Api::Elasticsearch::IndexedField
  def self.from(definition, document_format)
    new(definition, document_format)
  end

  def initialize definition, document_format
    @definition = definition

    # 'api_name' is used to match agains api queries
    @definition[:api_name] = @definition[:name]

    # 'name' is used to build the ES filters
    @definition[:name] = document_format.indexed_field_name(@definition[:name])

    if nested?
      @definition[:sub_fields] = @definition[:sub_fields].map do |field|
        self.class.from(field, document_format)
      end
    else
      add_defaults
    end

    @definition.freeze
  end

  def [] key
    @definition[key]
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

  def group_definitions
    @definition[:group_parameter_definition]
  end

  def type
    @definition[:type]
  end

  def name
    @definition[:name]
  end

  def nested?
    type == 'nested'
  end

  def sub_fields
    @definition[:sub_fields]
  end

private
  def default_date_filter_definition_boundary(suffix, boundary)
    {name: "#{default_name}_#{suffix}", type: 'range', boundary: boundary, options: { include_lower: true }}
  end

  def default_date_filter_definition
    [default_date_filter_definition_boundary('since', 'from'), default_date_filter_definition_boundary('until', 'to')]
  end

  def default_filter_definition
    if @definition[:type] == 'date'
      default_date_filter_definition
    else
      [{name: default_name, type: default_filter_type}]
    end
  end

  def default_group_definition
    if type == 'date'
      [
        {name: "year(#{default_name})", type: 'date', interval: 'year'},
        {name: "month(#{default_name})", type: 'date', interval: 'month'},
        {name: "week(#{default_name})", type: 'date', interval: 'week'},
        {name: "day(#{default_name})", type: 'date', interval: 'day'}
      ]
    else
      [{name: default_name, type: 'flat'}]
    end
  end

  def default_name
    @definition[:api_name].gsub(/_id$/, "")
  end

  def default_filter_type
    if @definition[:type] == 'integer'
      'match'
    else
      'wildcard'
    end
  end

  def add_defaults
    @definition[:type] = 'string' unless @definition[:type]

    @definition[:filter_parameter_definition] = if @definition[:filter_parameter_definition] && @definition[:filter_parameter_definition] != 'none'
      filter_definitions = @definition[:filter_parameter_definition]
      filter_definitions.each do |filter|
        filter[:name] = default_name unless filter[:name]
        filter[:type] = default_filter_type unless filter[:type]
      end
      filter_definitions
    else
      default_filter_definition
    end

    @definition[:group_parameter_definition] = if @definition[:group_parameter_definition] && @definition[:group_parameter_definition] != 'none'
      group_definitions = @definition[:group_parameter_definition]
      group_definitions.each do |group|
        group[:name] = default_name unless group[:name]
        group[:type] = 'flat' unless group[:type]
      end
      group_definitions
    else
      default_group_definition
    end
  end
end
