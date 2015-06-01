require 'spec_helper'

describe ElasticsearchMappingTemplate, elasticsearch: true do

  let(:manifest) do
    Manifest.create! definition: %{{
      "metadata" : {
        "version" : "1.0.0",
        "api_version" : "1.1.0",
        "device_models" : ["GX4001"]
      },
      "field_mapping" : { "event" : [
        {
          "target_field" : "temperature",
          "source" : {"lookup" : "Test.temp"},
          "core" : false,
          "type" : "integer",
          "pii" : false,
          "indexed" : true,
          "valid_values" : {
            "range" : {
              "min" : 0,
              "max" : 100
            }
          }
        },
        {
          "target_field" : "results[*].temperature",
          "source" : {"lookup" : "Test.temp"},
          "type" : "integer",
          "core" : false,
          "pii" : false,
          "indexed" :true,
          "valid_values" : {
            "range" : {
              "min" : 0,
              "max" : 100
            }
          }
        }
      ]}
    }}
  end

  let(:device_model) { DeviceModel.find_or_create_by(name: "GX4001") }
  let(:device)       { Device.make(device_model: device_model) }

  matcher :have_nested_keys do |keys|
    match do |hash|
      value = keys.inject hash do |h, key|
        h[key] if h && h.has_key?(key) rescue nil
      end
      value == @expected_value
    end

    chain :with_value do |expected_value|
      @expected_value = expected_value
    end

    failure_message_for_should do |hash|
      "expected hash to have keys nested #{keys} with value #{@expected_value} but found:\n#{hash.to_yaml}"
    end
  end

  shared_examples "has default mappings by" do

    it "being not blank" do
      subject.should_not be_blank
    end

    it "having location level dynamic template" do
      subject['dynamic_templates'][0].should have_nested_keys(['location_levels', 'path_match']).with_value('location.admin_level_*')
      subject['dynamic_templates'][0].should have_nested_keys(['location_levels', 'mapping', 'type']).with_value('string')
      subject['dynamic_templates'][0].should have_nested_keys(['location_levels', 'mapping', 'index']).with_value('not_analyzed')
    end

    it "mapping plain types" do
      subject.should have_nested_keys(['properties', 'start_time', 'type']).with_value('date')
      subject.should have_nested_keys(['properties', 'event_id', 'type']).with_value('string')
      subject.should have_nested_keys(['properties', 'error_code', 'type']).with_value('integer')
      subject.should have_nested_keys(['properties', 'laboratory_id', 'type']).with_value('integer')
      subject.should have_nested_keys(['properties', 'parent_locations', 'type']).with_value('string')
      subject.should have_nested_keys(['properties', 'location', 'type']).with_value('nested')
      subject.should have_nested_keys(['properties', 'race', 'type']).with_value('string')
    end

    it "mapping nested types" do
      subject.should have_nested_keys(['properties', 'results', 'type']).with_value('nested')
      subject.should have_nested_keys(['properties', 'results', 'properties', 'result', 'type']).with_value('string')
      subject.should have_nested_keys(['properties', 'results', 'properties', 'result', 'index']).with_value('not_analyzed')
      subject.should have_nested_keys(['properties', 'results', 'properties', 'result', 'fields', 'analyzed', 'type']).with_value('string')
      subject.should have_nested_keys(['properties', 'results', 'properties', 'condition', 'type']).with_value('string')
    end

  end


  shared_examples "has manifest mappings by" do

    it "being not blank" do
      subject.should_not be_blank
    end

    it "mapping plain custom fields" do
      subject.should have_nested_keys(['properties', 'custom_fields', 'type']).with_value('nested')
      subject.should have_nested_keys(['properties', 'custom_fields', 'properties', 'temperature', 'type']).with_value('integer')
    end

    it "mapping nested custom fields" do
      subject.should have_nested_keys(['properties', 'results', 'properties', 'custom_fields', 'type']).with_value('nested')
      subject.should have_nested_keys(['properties', 'results', 'properties', 'custom_fields', 'properties', 'temperature', 'type']).with_value('integer')
    end

  end

  context "default" do

    let(:template) { Cdx::Api.client.indices.get_template(name: 'cdp_events_template_test_default')['cdp_events_template_test_default'] }

    subject { template['mappings']['_default_'] }
    include_examples 'has default mappings by'

    it "should have a template name" do
      template['template'].should eq('cdp_institution_test*')
    end

    it "should have en empty default event mapping" do
      template['mappings']['event'].should eq({"dynamic_templates"=>[], 'properties' => {}})
    end

  end

  context "for manifest" do

    let(:event)     { TestResult.create_and_index({results: [{result: :positive}]}, device_events: [DeviceEvent.make(device: device)]) }
    let(:mapping)   { Cdx::Api.client.indices.get_mapping index: event.institution.elasticsearch_index_name }

    shared_examples "on mapping" do

      def mapping_for(name)
        mapping["cdp_institution_test_#{event.institution.id}"]['mappings'][name]
      end

      it "should have all types" do
        mapping["cdp_institution_test_#{event.institution.id}"]['mappings'].should_not be_blank
        mapping["cdp_institution_test_#{event.institution.id}"]['mappings'].should have_key('_default_')
        mapping["cdp_institution_test_#{event.institution.id}"]['mappings'].should have_key('event')
        mapping["cdp_institution_test_#{event.institution.id}"]['mappings'].should have_key("event_#{device_model.id}")
      end

      context "default" do
        subject { mapping_for('_default_') }
        include_examples 'has default mappings by'
      end

      context "for plain event" do
        subject { mapping_for('event') }
        include_examples 'has default mappings by'
      end

      context "for manifest" do
        subject { mapping_for("event_#{device_model.id}") }

        include_examples 'has default mappings by'
        include_examples 'has manifest mappings by'
      end

    end

    it "should index event with correct device model" do
      event.device_model.name.should eq("GX4001")
    end

    context "creating template for index" do
      before(:each) { manifest; event }
      include_examples 'on mapping'
    end

    context "updating template for index" do
      before(:each) { event; manifest }
      include_examples 'on mapping'

      it "should map location fields from dynamic template" do
        mapping_for('test').should have_nested_keys(['properties', 'location', 'properties', 'admin_level_0', 'type']).with_value('string')
      end
    end

  end

end
