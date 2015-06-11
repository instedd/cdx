require 'spec_helper'

describe Cdx do
  it "should provide a collection of fields" do
    Cdx.core_fields.map(&:scoped_name).sort.should =~([
      "device.institution_id",
      "device.lab_user",
      "device.laboratory_id",
      "device.serial_number",
      "device.uuid",
      "location.admin_levels",
      "location.id",
      "location.lat",
      "location.lng",
      "location.parents",
      "patient.gender",
      "sample.collection_date",
      "sample.id",
      "sample.type",
      "sample.uid",
      "sample.uuid",
      "test.assays.name",
      "test.assays.qualitative_result",
      "test.assays.quantitative_result",
      "test.end_time",
      "test.error_code",
      "test.error_description",
      "test.name",
      "test.patient_age",
      "test.qualitative_result",
      "test.reported_time",
      "test.start_time",
      "test.status",
      "test.type",
      "test.updated_time"
      ])
  end
end
