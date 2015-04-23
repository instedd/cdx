require 'spec_helper'

describe Manifest do

  context "mappings" do

    def manifest_definition(models, fields)
      {"metadata"=>
        {"device_models"=>models,
         "api_version"=>"1.1.0",
         "version"=>1,
         "source"=>{"type"=>"json"}},
       "field_mapping"=>
        {"event"=> fields.map { |field|
           {"target_field"=>field,
            "source"=>{"lookup"=>field},
            "core"=>false,
            "type"=>"string",
            "pii"=>false,
            "indexed"=>true}
          }
        }
      }.to_json
    end

    def model(name)
      name = "MODEL#{name}" if name.kind_of?(Fixnum)
      DeviceModel.where(name: name).first
    end

    matcher :have_template do |template|
      match do |client|
        @template = client.indices.get_template(name: template) rescue nil
        @template\
          && @template[template]\
          && (@type.nil? || @template[template]['mappings'][@type])\
          && (!@fields   || @fields.all?    { |field| @template[template]['mappings'][@type]['properties']['custom_fields']['properties'].has_key?(field) })\
          && (!@nofields || !@nofields.any? { |field| @template[template]['mappings'][@type]['properties']['custom_fields']['properties'].has_key?(field) })
      end

      chain(:with_type)     { |type| @type = type }
      chain(:with_custom_field)    { |field| (@fields ||= []) << field }
      chain(:without_custom_field) { |field| (@nofields ||= []) << field }

      failure_message_for_should do |client|
        "expected elasticsearch to have template #{template} with type #{@type || 'none'} with fields #{@fields.presence ? @fields.join(', ') : 'none'} and not #{@nofields.presence ? @nofields.join(', ') : 'none'} but found:\n#{@template.to_yaml}"
      end
    end

    context "on creation" do

      let(:definition) { manifest_definition(['MODEL1', 'MODEL2'], ['temperature']) }

      let(:model1) { DeviceModel.where(name: 'MODEL1').first }
      let(:model2) { DeviceModel.where(name: 'MODEL2').first }

      it "creates an elasticsearch template for each device model" do
        Manifest.create!(definition: definition)
        [model1, model2].each do |model|
          template_name = "cdp_events_template_test_#{model.id}"
          Cdx::Api.client.should have_template(template_name).with_type("event_#{model.id}")
        end
      end

      it "updates existing indices mappings" do
        institution = Institution.make
        institution.ensure_elasticsearch_index

        Manifest.create!(definition: definition)

        mappings = Cdx::Api.client.indices.get_mapping(index: institution.elasticsearch_index_name)[institution.elasticsearch_index_name]['mappings']
        mappings.should have_key("event_#{model1.id}")
        mappings.should have_key("event_#{model2.id}")
      end

    end

    context "on deletion" do

      let(:definition1)    { manifest_definition(['MODEL1'], ['field_1']) }
      let(:definition2)    { manifest_definition(['MODEL2'], ['field_2']) }
      let(:definition3)    { manifest_definition(['MODEL3'], ['field_3']) }

      let(:new_definition) { manifest_definition(['MODEL1', 'MODEL2'], ['field_new1', 'field_new2']) }

      def assert_original_templates
        (1..3).each do |index|
          model = model(index)
          template_name = "cdp_events_template_test_#{model.id}"
          Cdx::Api.client.should have_template(template_name).with_type("event_#{model.id}").with_custom_field("field_#{index}")
        end
      end

      it "restores former templates when new definition is deleted" do
        [definition1, definition2, definition3].each { |d| Manifest.create!(definition: d) }
        assert_original_templates

        manifest = Manifest.create!(definition: new_definition)

        [model(1), model(2)].each do |model|
          template_name = "cdp_events_template_test_#{model.id}"
          Cdx::Api.client.should have_template(template_name)
            .with_type("event_#{model.id}")
            .with_custom_field("field_new1")
            .with_custom_field("field_new2")
            .without_custom_field("field_1")
            .without_custom_field("field_2")
        end

        Cdx::Api.client.should have_template("cdp_events_template_test_#{model(3).id}")
          .with_type("event_#{model(3).id}")
          .without_custom_field("field_new1")
          .without_custom_field("field_new2")
          .with_custom_field("field_3")

        manifest.destroy!
        assert_original_templates
      end

      it "deletes templates when no manifest is present" do
        manifest = Manifest.create!(definition: new_definition)
        Cdx::Api.client.should have_template("cdp_events_template_test_#{model(1).id}")
        Cdx::Api.client.should have_template("cdp_events_template_test_#{model(2).id}")

        manifest.destroy!
        Cdx::Api.client.should_not have_template("cdp_events_template_test_#{model(1).id}")
        Cdx::Api.client.should_not have_template("cdp_events_template_test_#{model(2).id}")
      end

      # it "updates existing indices mappings" do
      #   institution = Institution.make
      #   institution.ensure_elasticsearch_index

      #   Manifest.create!(definition: temperature_definition)

      #   mappings = Cdx::Api.client.indices.get_mapping(index: institution.elasticsearch_index_name)[institution.elasticsearch_index_name]['mappings']
      #   mappings.should have_key("event_#{model1.id}")
      #   mappings.should have_key("event_#{model2.id}")
      # end

    end
  end
end
