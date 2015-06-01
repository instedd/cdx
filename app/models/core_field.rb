class CoreField
  def initialize scope, definition
    @scope = scope
    @definition = definition.with_indifferent_access

    if nested?
      @definition[:sub_fields] = @definition[:sub_fields].map do |field|
        self.class.new(field)
      end
    end

    @definition.freeze
  end

  def self.all
    @core_fields ||= YAML.load_file(File.join(Rails.root, "config/settings/core_fields.yml")).map do |scope_name, fields|
      FieldScope.new(scope_name, fields)
    end
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
end
