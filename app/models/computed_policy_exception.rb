class ComputedPolicyException < ApplicationRecord

  belongs_to :computed_policy, inverse_of: :exceptions

  delegate :include_subsites, to: :computed_policy

  include ComputedPolicyConcern

end
