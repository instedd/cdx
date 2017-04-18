require "bundler/setup"
require "cdx/api/elasticsearch"
require "pry-byebug"

describe "Cdx::Api::Elasticsearch::MappingTemplate" do

  describe "Mapping template" do
    let(:template) { Cdx::Api::Elasticsearch::MappingTemplate.new "cdx_tests_template" }

    it "maps the core fields" do
      expect(template.build_dynamic_templates).to eq([
        {
          "admin_levels" => {
            path_match: "*.admin_level_*",
            mapping: {type: :string, index: :not_analyzed}
          }
        },
        {
          "custom_fields" => {
            path_match: "*.custom_fields.*",
            mapping: { enabled: false }
          }
        }
      ])
    end

    it "maps the core fields" do
      expect(template.build_properties_mapping("test")).to eq(
        {
          "sample"=> {
            "properties" => {
              "id"=> {
                "type"=> "string",
                "index"=> "not_analyzed"
              },
              "uuid"=> {
                "type"=> "string",
                "index"=> "not_analyzed"
              },
              "type"=> {
                "type"=> "string",
                "index"=> "not_analyzed"
              },
              "custom_fields" => {
                "type" => "object"
              }
            }
          },
          "test"=> {
            "properties" => {
              "id"=> {
                "type"=>"string",
                "index"=>"not_analyzed"
              },
              "uuid" => {
                "type" => "string",
                "index" => "not_analyzed"
              },
              "start_time"=> {
                "type"=> "date",
                "index"=> "not_analyzed"
              },
              "end_time"=> {
                "type"=> "date",
                "index"=> "not_analyzed"
              },
              "reported_time"=> {
                "type"=> "date",
                "index"=> "not_analyzed"
              },
              "updated_time"=> {
                "type"=> "date",
                "index"=> "not_analyzed"
              },
              "error_code"=> {
                "type"=> "integer",
                "index"=> "not_analyzed"
              },
              "site_user"=> {
                "type"=> "string",
                "index"=> "not_analyzed"
              },
              "name" => {
                "type" => "string",
                "index" => "not_analyzed"
              },
              "status"=> {
                "type"=> "string",
                "index"=> "not_analyzed"
              },
              "assays" => {
                "type" => "nested",
                "properties" => {
                  "name" => {
                    "type" => "string",
                    "index" => "not_analyzed"
                  },
                  "condition" => {
                    "type" => "string",
                    "index" => "not_analyzed"
                  },
                  "result"=> {
                    "type"=> "string",
                    "index"=> "not_analyzed"
                  },
                  "quantitative_result"=> {
                    "type"=> "string",
                    "index"=> "not_analyzed"
                  }
                }
              },
              "type" => {
                "type" => "string",
                "index" => "not_analyzed"
              },
              "custom_fields" => {
                "type" => "object"
              }
            }
          },
          "device"=> {
            "properties" => {
              "uuid" => {
                "type" => "string",
                "index" => "not_analyzed"
              },
              "model" => {
                "type" => "string",
                "index" => "not_analyzed"
              },
              "serial_number"=> {
                "type"=> "string",
                "index"=> "not_analyzed"
              }
            }
          },
          "institution" => {
            "properties" => {
              "uuid" => {
                "type" => "string",
                "index" => "not_analyzed"
              }
            }
          },
          "site" => {
            "properties" => {
              "uuid" => {
                "type" => "string",
                "index" => "not_analyzed"
              },
              "path" => {
                "type" => "string",
                "index" => "not_analyzed"
              }
            }
          },
          "patient" => {
            "properties" => {
              "gender" => {
                "type" => "string",
                "index" => "not_analyzed"
              },
              "custom_fields" => {
                "type" => "object"
              }
            }
          },
          "location" => {
            "properties" => {
              "id" => {
                "type" => "string",
                "index" => "not_analyzed"
              },
              "parents" => {
                "type" => "string",
                "index" => "not_analyzed"
              },
              "admin_levels" => {
                "properties" => {}
              }
            }
          },
          "encounter" => {
            "properties" => {
              "uuid" => {
                "type" => "string",
                "index" => "not_analyzed"
              },
              "user_email"=> {
                "type"=> "string",
                "index"=> "not_analyzed"
              },
              "patient_age" => {
                "properties" => {
                  "in_millis" => {
                    "type" => "long",
                    "index" => "not_analyzed"
                  },
                  "milliseconds" => {
                    "type" => "integer",
                    "index" => "not_analyzed"
                  },
                  "seconds" => {
                    "type" => "integer",
                    "index" => "not_analyzed"
                  },
                  "minutes" => {
                    "type" => "integer",
                    "index" => "not_analyzed"
                  },
                  "hours" => {
                    "type" => "integer",
                    "index" => "not_analyzed"
                  },
                  "days" => {
                    "type" => "integer",
                    "index" => "not_analyzed"
                  },
                  "months" => {
                    "type" => "integer",
                    "index" => "not_analyzed"
                  },
                  "years" => {
                    "type" => "integer",
                    "index" => "not_analyzed"
                  }
                }
              },
              "start_time"=> {
                "type"=> "date",
                "index"=> "not_analyzed"
              },
              "end_time"=> {
                "type"=> "date",
                "index"=> "not_analyzed"
              },
              "diagnosis" => {
                "type" => "nested",
                "properties" => {
                  "name" => {
                    "type" => "string",
                    "index" => "not_analyzed"
                  },
                  "condition" => {
                    "type" => "string",
                    "index" => "not_analyzed"
                  },
                  "result"=> {
                    "type"=> "string",
                    "index"=> "not_analyzed"
                  },
                  "quantitative_result"=> {
                    "type"=> "string",
                    "index"=> "not_analyzed"
                  }
                }
              },
              "custom_fields" => {
                "type" => "object",
              },
            }
          }
        }
      )
    end
  end
end
