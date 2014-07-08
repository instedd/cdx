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
          parameter_definition: [
            {
              name: "since",
              type: :range,
              boundary: :from,
              options: {include_lower: true}
            },
            {
              name: "until",
              type: :range,
              boundary: :to,
              options: {include_lower: true}
            }
          ]
        },
        {
          name: :event_id,
          type: :string,
          parameter_definition: [
            {
              name: "event_id",
              type: :match
            }
          ]
        },
        {
          name: :device_uuid,
          type: :string,
          parameter_definition: [
            {
              name: "device",
              type: :match
            }
          ]
        },
        {
          name: :laboratory_id,
          type: :integer,
          parameter_definition: [
            {
              name: "laboratory",
              type: :match
            }
          ]
        },
        {
          name: :institution_id,
          type: :integer,
          parameter_definition: [
            {
              name: "institution",
              type: :match
            }
          ]
        },
        {
          name: :location_id,
          type: :integer,
          parameter_definition: []
        },
        {
          name: :parent_locations,
          type: :integer,
          parameter_definition: [
            {
              name: "location",
              type: :match
            }
          ]
        },
        {
          name: :age,
          type: :integer,
          parameter_definition: [
            {
              name: "age",
              type: :match
            },
            {
              name: "min_age",
              type: :range,
              boundary: :from,
              options: {include_lower: true}
            },
            {
              name: "max_age",
              type: :range,
              boundary: :to,
              options: {include_upper: true}
            }
          ]
        },
        {
          name: :assay_name,
          type: :string,
          parameter_definition: [
            {
              name: "assay_name",
              type: :wildcard
            }
          ]
        },
        {
          name: :device_serial_number,
          type: :string,
          parameter_definition: []
        },
        {
          name: :gender,
          type: :string,
          parameter_definition: [
            {
              name: "gender",
              type: :wildcard
            }
          ]
        },
        {
          name: :uuid,
          type: :string,
          parameter_definition: [
            {
              name: "uuid",
              type: :match
            }
          ]
        },
        {
          name: :start_time,
          type: :date,
          parameter_definition: []
        },
        {
          name: :system_user,
          type: :string,
          parameter_definition: []
        },
        {
          name: :results,
          type: :nested,
          sub_fields: [
            {
              name: :result,
              type: :multi_field,
              parameter_definition: [
                {
                  name: "result",
                  type: :wildcard
                }
              ]
            },
            {
              name: :condition,
              type: :string,
              parameter_definition: [
                {
                  name: "condition",
                  type: :wildcard
                }
              ]
            }
          ]
        }
      ]
    end
  end
end
