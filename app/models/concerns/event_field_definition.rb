module EventFieldDefinition
  extend ActiveSupport::Concern

  included do
    def self.sensitive_fields
      [
        :patient_id,
        :patient_name,
        :patient_telephone_number,
        :patient_zip_code,
      ]
    end

    def self.searchable_fields
      [
        {
          name: :created_at,
          type: :date,
          queryable_options: [
            {"since" => {range: [from: {include_lower: true}]}},
            {"until" => {range: [to: {include_lower: true}]}}
          ]
        },
        {
          name: :event_id,
          type: :integer,
          queryable_options: [{"event_id" => :match}]
        },
        {
          name: :device_uuid,
          type: :string,
          queryable_options: [{"device" => :match}]
          },
        {
          name: :laboratory_id,
          type: :integer,
          queryable_options: [{"laboratory" => :match}]
          },
        {
          name: :institution_id,
          type: :integer,
          queryable_options: [{"institution" => :match}]
        },
        {
          name: :location_id,
          type: :integer,
          queryable_options: []
        },
        {
          name: :parent_locations,
          type: :integer,
          queryable_options: [{"location" => :match}]
          },
        {
          name: :age,
          type: :integer,
          queryable_options: [
            {"age" => :match},
            {"min_age" => {range: [from: {include_lower: true}]}},
            {"max_age" => {range: [to: {include_upper: true}]}}
          ]
        },
        {
          name: :assay_name,
          type: :string,
          queryable_options: [{"assay_name" => :wildcard}]
        },
        {
          name: :device_serial_number,
          type: :string,
          queryable_options: []
        },
        {
          name: :gender,
          type: :string,
          queryable_options: [{"gender" => :wildcard}]
        },
        {
          name: :uuid,
          type: :string,
          queryable_options: [{"uuid" => :match}]
        },
        {
          name: :start_time,
          type: :date,
          queryable_options: []
        },
        {
          name: :system_user,
          type: :string,
          queryable_options: []
        },
        {
          name: :results,
          type: :nested,
          sub_fields: [
            {
              name: :result,
              type: :multi_field,
              queryable_options: [{"result" => :wildcard}]
            },
            {
              name: :condition,
              type: :string,
              queryable_options: [{"condition" => :wildcard}]
            }
          ]
        }
      ]
    end
  end
end
