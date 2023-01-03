require 'spec_helper'

describe Sample do
  context "entity field scopes" do
    let(:institution) { Institution.make }

    let!(:samples) do
      [
        Sample.make!(institution: institution, core_fields: {}),
        Sample.make!(institution: institution, date_produced: 1.month.ago),
        Sample.make!(institution: institution, date_produced: 1.week.ago),
      ]
    end

    it "existing_entity" do
      assert_equal [samples[1], samples[2]], Sample.existing_entity(:date_produced)
    end

    it "missing_entity" do
      assert_equal [samples[0]], Sample.missing_entity(:date_produced)
    end

    it "where_entity" do
      assert_equal [samples[0]], Sample.where_entity(:date_produced, nil)
      assert_equal [samples[1]], Sample.where_entity(:date_produced, samples[1].date_produced)
    end

    it "where_entity_not" do
      assert_equal [samples[1], samples[2]], Sample.where_entity_not(:date_produced, nil)
      assert_equal [samples[2]], Sample.where_entity_not(:date_produced, samples[2].date_produced)
    end
  end
end

