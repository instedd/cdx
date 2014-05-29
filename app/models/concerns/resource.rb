require 'active_support/concern'
module Resource
  extend ActiveSupport::Concern
  included do
    def self.filter_by_resource(resource)
      unless resource =~ /#{Policy::PREFIX}:#{name.underscore}\/(.*)/
        return nil
      end

      match = $1
      if match == "*"
        return self
      end

      where(id: match)
    end

    def filter_by_resource(resource)
      unless resource =~ /#{Policy::PREFIX}:#{self.class.name.underscore}\/(.*)/
        return nil
      end

      match = $1
      if match == "*"
        return self
      end

      if match.to_i == id
        return self
      end

      nil
    end
  end
end
