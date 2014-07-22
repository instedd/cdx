class Cdx::Api::Elasticsearch::IndexedField
  def self.from definition
    new definition
  end

  def initialize definition
    @definition = definition

    if nested?
      @definition[:sub_fields] = @definition[:sub_fields].map do |field|
        self.class.from field
      end
    else
      add_defaults
    end

    @definition.freeze
  end

  def [] key
    @definition[key]
  end

  def grouping_detail_for field_name, values=nil
    if nested?
      group = sub_fields.detect do |field|
        field.grouping_detail_for field_name, values
      end
      {type: type, name: name, sub_fields: group} if group
    else
      definition = group_definitions.detect do |definition|
        definition[:name] == field_name
      end
      if definition
        grouping_def = definition.clone
        if grouping_def[:type] == "range"
          if values
            grouping_def[:ranges] = values
          else
            grouping_def[:type] = 'flat'
          end
        end

        if grouping_def[:type] == "kind"
          grouping_def[:value] = values
        end

        grouping_def[:field] = @definition
        grouping_def
      end
    end
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

  def default_filter_definition
    [{name: default_name, type: default_filter_type}]
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
    @definition[:name].gsub(/_id$/, "")
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
