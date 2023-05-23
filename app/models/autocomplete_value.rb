class AutocompleteValue < ApplicationRecord
  belongs_to :institution
  validates :value, :field_name, presence: true

  validates :value, uniqueness: { scope: [:field_name, :institution_id] }
end
