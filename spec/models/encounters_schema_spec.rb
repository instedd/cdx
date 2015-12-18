require 'spec_helper'

describe EncountersSchema do

  context "encounters fields" do

    it "renders all encounters scopes" do
      expect(EncountersSchema.new.build['properties'].keys).to contain_exactly("institution", "site", "patient", "encounter")
    end

  end

end
