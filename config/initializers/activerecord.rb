class ActiveRecord::Base

  def destroy_restrict_associations
    self.class.reflect_on_all_associations.select do |assoc|
      assoc.options[:dependent] == :restrict_with_error || assoc.options[:dependent] == :restrict_with_exception
    end
  end

  def destroy_restrict_associations_with_elements
    destroy_restrict_associations.select do |assoc|
      (assoc.macro == :has_one && self.send(assoc.name).not_nil?) ||
        (assoc.macro == :has_many && self.send(assoc.name).any?)
    end
  end

  def can_destroy?
    destroy_restrict_associations_with_elements.empty?
  end
  
end
