module Resource
  extend ActiveSupport::Concern
  include Policy::Actions

  # Note: we could use an instance variable to store the classes as this module
  # is included, but Rails reloads every class in development mode, so the class
  # variable ends nil/empty.
  def self.all
    [Institution, Laboratory, Device, Location]
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
    return nil
  end

  included do
    def self.find_resource(resource_filter)
      match_resource(resource_filter) do |match|
        find match
      end
    end

    def self.filter_by_resource(resource_filter)
      match_resource(resource_filter) do |match|
        where(id: match)
      end
    end

    def filter_by_resource(resource_filter)
      self.class.match_resource(resource_filter, self) do |match|
        if match.to_i == id
          return self
        end
      end
    end

    def filter_by_owner(user)
      self
    end

    def self.filter_by_owner(user)
      self
    end

    def self.filter_by_query(query)
      self
    end

    def filter_by_query(query)
      self
    end

    def self.match_resource(resource_filter, resource=self)
      unless resource_filter =~ resource_matcher
        return nil
      end

      match, query = $1, $2

      if match == "*" || match.nil?
        if query
          query = Rack::Utils.parse_nested_query(query)
          resource.filter_by_query(query)
        else
          resource
        end
      else
        yield match, query
      end
    end

    def self.resource_name_prefix
      "#{PREFIX}:#{name.underscore}"
    end

    def self.resource_matcher
      /#{resource_name_prefix}(?:\/(.*))?(?:\?(.*))?/
    end

    def self.resource_name
      resource_name_prefix
    end

    def resource_name
      "#{self.class.resource_name_prefix}/#{id}"
    end
  end
end
