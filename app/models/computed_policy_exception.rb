class ComputedPolicyException < ActiveRecord::Base

  belongs_to :computed_policy, inverse_of: :exceptions

  include ComputedPolicyConcern

end
