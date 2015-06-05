require 'spec_helper'

describe JsonEventParser do
  let(:parser) { JsonEventParser.new }

  it "looks up an element in the root" do
    data = {
      "a_key" => "it's value",
      "other_key" => "other value"
    }

    parser.lookup("a_key", data).should eq("it's value")
    parser.lookup("other_key", data).should eq("other value")
    parser.lookup("inexistent_key", data).should be_nil
  end

  it "looks up a nested element" do
    data = {
      "a_key" => "it's value",
      "nested_object" => {
        "first_key" => "first value",
        "second_key" => "second value"
      }
    }

    parser.lookup("nested_object.first_key", data).should eq("first value")
    parser.lookup("nested_object.second_key", data).should eq("second value")
    parser.lookup("nested_object.inexistent_key", data).should be_nil
    parser.lookup("inexistent_key.inexistent_key", data).should raise_error
  end

  it "looks up a nested element" do
    data = {
      "a_key" => "it's value",
      "nested_object" => {
        "first_key" => "first value",
        "second_key" => "second value"
      }
    }

    parser.lookup("nested_object.first_key", data).should eq("first value")
    parser.lookup("nested_object.second_key", data).should eq("second value")
    parser.lookup("nested_object.inexistent_key", data).should be_nil
    parser.lookup("inexistent_key.inexistent_key", data).should raise_error
  end

  it "looks up the root element" do
    data = {
      "a_key" => "it's value",
      "nested_object" => {
        "first_key" => "first value",
        "second_key" => "second value"
      }
    }

    parser.lookup("nested_object.first_key", data, data).should eq("first value")
    parser.lookup("first_key", data["nested_object"], data).should eq("first value")
    parser.lookup("$.nested_object.first_key", data["nested_object"], data).should eq("first value")

    parser.lookup("a_key", data, data).should eq("it's value")
    parser.lookup("nested_object.a_key", data, data).should be_nil
    parser.lookup("a_key", data["nested_object"], data).should be_nil
    parser.lookup("$.a_key", data["nested_object"], data).should eq("it's value")
  end

  it "parses using a root path" do
    data = {
      'root_key' => 'root_value',
      'children' => [
        {
          'children_1_key' => 'children_1_value'
        },
        {
          'children_2_key' => 'children_2_value'
        }
      ]
    }

    parsed_data = parser.load(Oj.dump(data), 'children')
    parsed_data.should eq(data['children'])
  end

end
