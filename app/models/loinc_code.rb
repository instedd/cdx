class LoincCode < ActiveRecord::Base

  def description
    "#{self.loinc_number} - #{self.component}"
  end
end
