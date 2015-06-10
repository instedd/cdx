class Cdx::Field
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
