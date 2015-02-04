require 'spec_helper'

describe Subscriber do
  let(:model){DeviceModel.make}
  let(:device){Device.make device_model: model}
  let(:institution){device.institution}
  let(:laboratory){device.laboratories.first}

  it "generates a correct filter_event query" do
    query = {"condition" => "mtb", "laboratory" => laboratory.id.to_s}
    fields = ["condition", "result", "patient_name"]
    url = "http://mbuilder-stg.instedd.org/external/application/118/trigger/cdp_trigger"

    filter = Filter.make query: query
    subscriber = Subscriber.make fields: fields, url: url, filter: filter

    callback_query = "http://mbuilder-stg.instedd.org/external/application/118/trigger/cdp_trigger?condition=mtb&patient_name=jdoe&result=positive"

    stub_request(:post, callback_query).with(:headers => {'Accept'=>'*/*; q=0.5, application/xml', 'Accept-Encoding'=>'gzip, deflate', 'Content-Length'=>'0', 'User-Agent'=>'Ruby'}).
         to_return(:status => 200, :body => "", :headers => {})

    manifest = Manifest.make definition: %{
      {
        "metadata": {
          "version": "1",
          "api_version": "1",
          "device_models": "#{model.name}",
          "source_data_type" : "json"
        },
        "field_mapping" : [
          {
            "target_field" : "results[*].result",
            "source" : {"lookup" : "result"},
            "core" : true,
            "type" : "enum",
            "options" : ["positive","negative"]
          },
          {
            "target_field" : "results[*].condition",
            "source" : {"lookup" : "condition"},
            "core" : true,
            "type" : "enum",
            "options" : ["mtb","flu_a"]
          },
          {
            "target_field" : "patient_name",
            "source" : {"lookup" : "patient_name"},
            "core" : true,
            "type" : "string"
          }
        ]
      }
    }

    Manifest.count.should eq(1)
    json = %{{ "result": "positive", "condition" : "mtb", "patient_name" : "jdoe" }}
    e = Event.create_or_update_with device, json
    client = Cdx::Api.client
    client.indices.refresh index: institution.elasticsearch_index_name

    Event.count.should eq(1)

    Subscriber.notify_all

    WebMock.should have_requested(:post, callback_query)
  end

end
