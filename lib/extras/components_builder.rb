module ComponentsBuilder
  class Component

    attr_reader    :context, :attributes
    cattr_accessor :classes

    def initialize(context, attributes)
      @context = context
      @attributes = attributes
      @data = Hash.new
    end

    def to_h
      @attributes.merge(@data)
    end

    def self.create!(name, sections, attributes)
      (self.classes ||= {})[name] = Class.new(self) do
        sections.each do |section|
          define_method section do |*args, &block|
            instance_variable_get("@data")[section] = context.capture(&block)
          end
        end
      end
    end

  end

  def define_component(name, options)
    Component.create!(name, options[:sections], options[:attributes])

    class_eval %(
      def #{name}(attributes, &block)
        component = Component.classes[:#{name}].new(self, attributes)
        block.call(component)
        render partial: "components/#{name}", locals: { :#{name} => component.to_h }
      end
    )
  end
end
