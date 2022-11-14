class ChangeSampleConcentrationsToSingleValue < ActiveRecord::Migration

  def up
    Sample.find_each do |sample|
        number = sample.core_fields.key?("concentration_number").try(&:to_i)
        exponent = sample.core_fields.key?("concentration_exponent").try(&:to_i)
        if number && exponent
          sample.core_fields["concentration"] = number * (10**exponent)
          sample.save
      end
    end
  end

  def down
  end
end
