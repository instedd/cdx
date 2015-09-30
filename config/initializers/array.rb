class Array

  def substract(other_array, &are_equal)
    self.reject do |elem|
      other_array.any? do |other_elem|
        are_equal.call(elem, other_elem)
      end
    end
  end

end
