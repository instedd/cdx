require "bundler/setup"
require "cdx/api/elasticsearch"
require "pry-byebug"

require "support/elasticsearch_indices.rb"
require "support/cdx_api_helpers.rb"

describe "Cdx::Api::Elasticsearch::MappingTemplate" do

  describe "Mapping template" do
    let(:template) { Cdx::Api::Elasticsearch::MappingTemplate.new "cdx_tests_template" }

    it "maps the core fields" do
      template.build_properties_mapping.should eq(
        {
          "sample"=> {
            "properties" => {
              "uuid"=> {
                "type"=> "string",
                "index"=> "not_analyzed"
              },
              "id"=> {
                "type"=> "string",
                "index"=> "not_analyzed"
              },
              "type"=> {
                "type"=> "string",
                "index"=> "not_analyzed"
              }
            }
          },
          "test"=> {
            "properties" => {
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
              "patient_age" => {
                "type" => "integer",
                "index" => "not_analyzed"
              },
              "name" => {
                "type" => "string",
                "index" => "not_analyzed"
              },
              "status"=> {
                "type"=> "string",
                "index"=> "not_analyzed"
              },
              "qualitative_result"=> {
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
                  "qualitative_result"=> {
                    "type"=> "string",
                    "index"=> "not_analyzed"
                  }
                }
              },
              "type" => {
                "type" => "string",
                "index" => "not_analyzed"
              }
            }
          },
          "device"=> {
            "properties" => {
              "uuid" => {
                "type" => "string",
                "index" => "not_analyzed"
              },
              "name" => {
                "type" => "string",
                "index" => "not_analyzed"
              },
              "lab_user"=> {
                "type"=> "string",
                "index"=> "not_analyzed"
              },
              "serial_number"=> {
                "type"=> "string",
                "index"=> "not_analyzed"
              }
            }
          },
          "institution" => {
            "properties" => {
              "id" => {
                "type" => "string",
                "index" => "not_analyzed"
              },
              "name" => {
                "type" => "string",
                "index" => "not_analyzed"
              }
            }
          },
          "laboratory" => {
            "properties" => {
              "id" => {
                "type" => "string",
                "index" => "not_analyzed"
              },
              "name" => {
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
              }
            }
          },
          "location" => {
            "properties" => {
              "parents" => {
                "type" => "string",
                "index" => "not_analyzed"
              },
              "admin_levels" => {
                "properties" => {}
              }
            }
          }
        }
      )
    end

  end

end
