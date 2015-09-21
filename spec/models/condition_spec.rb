require 'spec_helper'

describe Condition do
  it "checks name validity" do
    expect(Condition.valid_name?("MTB")).to be_falsey
    expect(Condition.valid_name?("mtb")).to be_truthy
    expect(Condition.valid_name?("malaria_pf")).to be_truthy
    expect(Condition.valid_name?("malaria_pf2")).to be_truthy
    expect(Condition.valid_name?("_foo")).to be_falsey
    expect(Condition.valid_name?("123")).to be_falsey
  end
end
