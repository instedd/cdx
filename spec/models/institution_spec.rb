require 'spec_helper'

describe Institution do
  let(:user) {User.make}

  it "creates predefined roles for institution" do
    expect {
      Institution.make user_id: user.id
    }.to change(Role, :count).by(2)
  end
end
