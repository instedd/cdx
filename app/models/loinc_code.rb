class LoincCode < ApplicationRecord

  def description
    "#{self.loinc_number} - #{self.component}"
  end
end
