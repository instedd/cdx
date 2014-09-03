require 'spec_helper'

describe Device do
  it { should validate_presence_of :device_model }
end