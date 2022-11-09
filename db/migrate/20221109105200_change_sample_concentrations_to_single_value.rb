class ChangeSampleConcentrationsToSingleValue < ActiveRecord::Migration

  def up
    Sample.find_each do |sample|
      if sample.core_fields.key?("concentration_number") && sample.core_fields.key?("concentration_exponent")
        sample.core_fields["concentration"] = sample.core_fields["concentration_number"].to_i * (10**(sample.core_fields["concentration_exponent"].to_i))
        sample.core_fields.delete("concentration_number")
        sample.core_fields.delete("concentration_exponent")
        sample.save
      else
        sample.core_fields["concentration"] = 0
        sample.save
      end
    end
  end

  def down
  end
end

Sample.find_each do |sample|
  if sample.core_fields.key?("concentration_number") && sample.core_fields.key?("concentration_exponent")
    sample.core_fields["concentration"] = sample.core_fields["concentration_number"].to_i * (10**(sample.core_fields["concentration_exponent"].to_i))
    sample.core_fields.delete("concentration_number")
    sample.core_fields.delete("concentration_exponent")
    sample.save
  end
end