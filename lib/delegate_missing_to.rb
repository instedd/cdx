# Backports `#delegate_missing_to` from Rails 5.1

unless Module.respond_to?(:delegate_missing_to)
  class Module
    def delegate_missing_to(target)
      target = target.to_s
      target = "self.#{target}" if DELEGATION_RESERVED_METHOD_NAMES.include?(target)

      module_eval <<-RUBY, __FILE__, __LINE__ + 1
        def respond_to_missing?(name, include_private = false)
          # It may look like an oversight, but we deliberately do not pass
          # +include_private+, because they do not get delegated.

          #{target}.respond_to?(name) || super
        end

        def method_missing(method, *args, &block)
          if #{target}.respond_to?(method)
            #{target}.public_send(method, *args, &block)
          else
            super
          end
        end
        RUBY
    end
  end
end
