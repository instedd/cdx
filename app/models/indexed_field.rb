class IndexedField
  def self.from definition
    new definition
  end

  def initialize definition
    @definition = definition

    if @definition[:type] == 'nested'
      @definition[:sub_fields] = @definition[:sub_fields].map do |field|
        self.class.from field
      end
    else
      add_defaults
    end
  end

  def [] key
    @definition[key]
  end

private

  def default_filter_definition
    [{name: default_name, type: default_filter_type}]
  end

  def default_group_definition
    [{name: default_name, type: 'flat'}]
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
