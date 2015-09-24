module Resource
  extend ActiveSupport::Concern
  include Policy::Actions

  def self.all
    @all_resources ||= [Institution, Laboratory, Device, Location].freeze
  end

  def self.resolve(resource_string)
    return all if resource_string == "*"
    resource_class = all.find{|r| resource_string =~ r.resource_matcher} or raise "Resource not found"
    [resource_class, $1, Rack::Utils.parse_nested_query($2)]
  end

  included do

    delegate :resource_type, :resource_class, :none, to: :class

    def resource_name
      "#{self.class.resource_name_prefix}/#{id}"
    end

    def filter(conditions)
      self.class.where(id: self.id).filter(conditions)
    end

  end

  class_methods do

    def resource_name_prefix
      "#{PREFIX}:#{name.underscore}"
    end

    def resource_matcher
      /#{resource_name_prefix}(?:\/(.*))?(?:\?(.*))?/
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

    def filter(conditions)
      where(conditions)
    end

  end
end
