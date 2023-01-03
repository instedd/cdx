class MigrateEntityFieldsToJson < ActiveRecord::Migration[5.0]
  MODEL_CLASSES = [
    Batch,
    Box,
    Encounter,
    Patient,
    QcInfo,
    Sample,
    TestResult,
  ]

  def up
    MODEL_CLASSES.each do |model_class|
      migrate_entity_fields_to_json(model_class, :core_fields)
      migrate_entity_fields_to_json(model_class, :custom_fields)
    end
  end

  def down
    MODEL_CLASSES.each do |model_class|
      migrate_entity_fields_to_yaml(model_class, :core_fields)
      migrate_entity_fields_to_yaml(model_class, :custom_fields)
    end
  end

  private

  def migrate_entity_fields_to_json(model_class, column_name)
    yaml_column_name = "yaml_#{column_name}"

    rename_column model_class.table_name, column_name, yaml_column_name
    add_column model_class.table_name, column_name, :json
    model_class.reset_column_information

    model_class.find_each do |sample|
      sample.update(column_name: YAML.load(sample.__send__(yaml_column_name)))
    end

    remove_column model_class.table_name, yaml_column_name
  end

  def migrate_entity_fields_to_yaml(model_class, column_name)
    json_column_name = "json_#{column_name}"

    rename_column model_class.table_name, column_name, json_column_name
    add_column model_class.table_name, column_name, :text
    model_class.reset_column_information

    model_class.find_each do |sample|
      sample.update(column_name: sample.__send__(json_column_name))
    end

    remove_column model_class.table_name, json_column_name
  end
end
