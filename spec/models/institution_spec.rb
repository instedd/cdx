require 'spec_helper'

describe Institution do
  let(:user) {User.make}
  let(:institution) {Institution.make user_id: user.id}
end
