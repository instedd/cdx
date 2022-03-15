require 'tempfile'

class EntityCsvBuilder
  def initialize(scope, query, filename)
    @fields = Cdx::Fields[scope]
    @query = query
    @dynamic_headers = Hash[dynamic_fields.map{|f| [f, Set.new]}] # e.g. Field(location.admin_levels) => ['admin_0', 'admin_1']
    @multi_headers = Hash[multi_fields.map{|f| [f, 0]}] # e.g. Field(test.assays) => 4, Field(encounter.diagnosis) => 2
    @custom_headers = Hash[scopes.map{|s| [s.name, Set.new]}] # e.g. "test" => ["custom1", "custom2"], "sample" => ["custom3"]
    @data_tempfile = Tempfile.new("#{filename}.data", Rails.root.join('tmp'))
  end

  def build
    begin
      # The first pass writes no headers, and for each test, a row with all core fields, one field per scope
      # with its custom fields serialised, and one field per multi field with all its values serialised as well
      data_csv = CSV.new(@data_tempfile)
      while @query.next_page
        @query.execute[@fields.result_name].each do |test|
          data_csv << build_row(test)
        end
      end

      # Now that we know all the possible values for multi fields and custom fields,
      # the second pass writes the definitive headers, and expands all serialised fields
      # honouring the same order used for the headers
      @data_tempfile.rewind
      yield build_headers.to_csv
      data_csv.each do |line|
        yield expand_row(line).to_csv
      end
    ensure
      # Make sure the data tempfile is closed after building so it is collected
      @data_tempfile.close
      @data_tempfile.unlink
    end
  end

  alias_method :each, :build

  private

  def build_headers
    core_fields.map { |field| format_header(field.scope.name, field.name) } \
      + dynamic_headers_labels \
      + multi_headers_labels \
      + custom_headers_labels
  end

  def dynamic_headers_labels
    @dynamic_headers.flat_map do |field, sub_fields|
      sub_fields.map { |sub_field| format_header(field.scope.name, field.name, sub_field) }
    end
  end

  def multi_headers_labels
     @multi_headers.flat_map do |field, count|
       if field.nested?
         count.times.to_a.product(field.sub_fields).map do |i, sub_field|
           "#{format_header(field.scope.name, field.name, sub_field.name)} #{i+1}"
         end
       else
         count.times.map do |i|
           "#{format_header(field.scope.name, field.name)} #{i+1}"
         end
       end
     end
  end

  def custom_headers_labels
    @custom_headers.flat_map do |scope, fields|
      fields.map { |field| format_header(scope, field) }
    end
  end

  def format_header(scope_name, field_name, sub_field_name=nil)
    [scope_name, field_name, sub_field_name].compact.join(" ").humanize
  end

  def build_row(test)
    row = []

    # Add all core fields
    core_fields.each do |field|
      row << value_for(test, field)
    end

    # Serialise the contents of each dynamic field in a new cell
    dynamic_fields.each do |field|
      fields = test[field.scope.name][field.name]
      row << (fields ? fields.to_json : nil)
      fields.keys.each do |key|
        @dynamic_headers[field] << key
      end unless fields.blank?
    end

    # Finally add all multi fields and register the max count of items
    multi_fields.each do |field|
      values = test[field.scope.name][field.name]
      row << (values ? values.to_json : nil)
      @multi_headers[field] = values.count if values && @multi_headers[field] < values.count
    end

    # Serialise custom fields per scope and register headers
    @fields.core_field_scopes.each do |scope|
      custom_fields = test[scope.name]['custom_fields'] || {}
      row << custom_fields.to_json
      custom_fields.each do |custom_key, custom_value|
        @custom_headers[scope.name] << custom_key
      end
    end

    row
  end

  def expand_row(row)
    # Copy core fields
    expanded = row.shift(core_fields.count)

    # Expand dynamic fields, each cell has the serialised content of each dynamic field
    test_dynamic_fields = row.shift(@dynamic_headers.count).map{|data| Oj.load(data || '') || {}}
    @dynamic_headers.each_with_index do |field_keys, index|
      field, keys = field_keys
      keys.each do |key|
        expanded << (test_dynamic_fields.dig(index, key))
      end
    end

    # Expand multi fields
    test_multi_fields = row.shift(@multi_headers.count).map{|data| Oj.load(data || '') || []}
    @multi_headers.each_with_index do |value, index|
      field, count = value
      count.times do |repetition|
        if field.nested?
          field.sub_fields.each do |sub_field|
            expanded << format_value(test_multi_fields.dig(index, repetition, sub_field.name))
          end
        else
          expanded << format_value(test_multi_fields.dig(index, repetition))
        end
      end
    end

    # Expand custom fields based on calculated custom headers
    test_custom_fields = row.shift(@custom_headers.count).map{|data| Oj.load(data || '') || Hash.new}
    @custom_headers.each_with_index do |scope_fields, index|
      scope, fields = scope_fields
      fields.each do |field|
        expanded << format_value(test_custom_fields.dig(index, field))
      end
    end

    expanded
  end

  def value_for(test, field)
    format_value(test[field.scope.name][field.name], field)
  end

  def format_value(value, field = nil)
    if field
      field.humanize(value)
    else
      value
    end
  end

  def core_fields
    @core_fields ||= @fields.first_level_core_fields\
      .reject{|f| f.dynamic? || f.nested? || f.multiple? || blacklisted?(f)}
  end

  def multi_fields
    @multi_fields ||= @fields.first_level_core_fields\
      .select{|f| f.nested? || f.multiple?}\
      .reject{|f| f.dynamic? || blacklisted?(f)}
  end

  def dynamic_fields
    @dynamic_fields ||= @fields.first_level_core_fields\
      .select{|f| f.dynamic?}
      .reject{|f| blacklisted?(f)}
  end

  def scopes
    @scopes ||= @fields.core_field_scopes
  end

  def blacklisted?(field)
    field.pii? || ["location.parents", "site.path"].include?(field.scoped_name)
  end

end
