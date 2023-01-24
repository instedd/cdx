module Resource
  extend ActiveSupport::Concern
  include Policy::Actions

  def self.all
    @all_resources ||= [
      Institution,
      Site,
      Device,
      DeviceModel,
      TestResult,
      Encounter,
      Role,
      User,
      Patient,
      Sample,
      Batch,
      Box,
      BoxReport
    ].freeze
  end

  def self.resolve(resource_string)
    return all if resource_string == "*"
    resource_class = all.find{|r| resource_string =~ r.resource_matcher} or raise "Resource not found: #{resource_string}"
    match = ($1 == '*') ? nil : $1
    [resource_class, match.presence, Rack::Utils.parse_nested_query($2)]
  end

  class NotSupportedException < StandardError; end

  included do

    delegate :resource_type, :resource_class, to: :class

    def resource_name
      "#{self.class.resource_name_prefix}/#{id}"
    end

  end

  class_methods do

    def supports_query?(query)
      query.keys.all? { |key| supports_condition?(key) }
    end

    def supports_condition?(key)
      column_names.include?("#{key.to_s}_id")
    end

    def supports_identifier?(key)
      key.blank? || key.kind_of?(Integer) || key.strip.match(/\A\d+\z/)
    end

    def resource_name_prefix
      name.camelize(:lower)
    end

    def resource_matcher
      /\A#{resource_name_prefix}(?:\/(.*))?(?:\?(.*))?\z/
    end

    def resource_type
      resource_name
    end

    def resource_class
      self
    end

    def resource_name
      resource_name_prefix
    end
  end
end
