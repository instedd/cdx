require 'active_support/concern'
module Resource
  extend ActiveSupport::Concern
  include Policy::Actions

  def self.add_resource(resource)
    (@resources||=[]) << resource
  end

  def self.all
    @resources.clone
  end

  def self.find(resource_string)
    if resource_string == "*"
      return all
    end
    all.each do |resource|
      if result = resource.find_resource(resource_string)
        return result
      end
    end
  end

  included do

    def self.find_resource(resource)
      match_resource(resource) do |match|
        find match
      end
    end

    def self.filter_by_resource(resource)
      match_resource(resource) do |match|
        where(id: match)
      end
    end

    def filter_by_resource(resource)
      self.class.match_resource(resource) do |match|
        if match.to_i == id
          return self
        end
      end
    end

    def self.match_resource(resource)
      unless resource =~ resource_matcher
        return nil
      end

      match = $1
      if match == "*"
        return self
      end

      yield match
    end

    def self.resource_name_prefix
      "#{PREFIX}:#{name.underscore}"
    end

    def self.resource_matcher
      /#{resource_name_prefix}\/(.*)/
    end

    def self.resource_name
      "#{resource_name_prefix}/*"
    end

    def resource_name
      "#{self.class.resource_name_prefix}/#{id}"
    end

    Resource.add_resource(self)
  end
end
