class Object
  def not_nil?
    !nil?
  end

  def is_an? object
    is_a? object
  end

  def subclass_responsibility
    raise 'Subclasses must redefine this method'
  end

  def self.subclass_responsibility(*args)
    args.each do |method|
      self.class_eval <<-METHOD
        def #{method}(*args)
          subclass_responsibility
        end
      METHOD
    end
  end
end
