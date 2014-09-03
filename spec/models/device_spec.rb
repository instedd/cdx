require 'spec_helper'

describe Device do
  it { should validate_presence_of :device_model }
  it { should validate_presence_of :name }
  it { should validate_presence_of :institution }
end