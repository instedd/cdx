require 'spec_helper'

describe JsonMessageParser do
  let(:parser) { JsonMessageParser.new }

  it "looks up an element in the root" do
    data = {
      "a_key" => "it's value",
      "other_key" => "other value"
    }

    expect(parser.lookup("a_key", data)).to eq("it's value")
    expect(parser.lookup("other_key", data)).to eq("other value")
    expect(parser.lookup("inexistent_key", data)).to be_nil
  end

  it "looks up a nested element" do
    data = {
      "a_key" => "it's value",
      "nested_object" => {
        "first_key" => "first value",
        "second_key" => "second value"
      }
    }

    expect(parser.lookup("nested_object.first_key", data)).to eq("first value")
    expect(parser.lookup("nested_object.second_key", data)).to eq("second value")
    expect(parser.lookup("nested_object.inexistent_key", data)).to be_nil
    pending
    expect { parser.lookup("inexistent_key.inexistent_key", data) }.to raise_error
  end

  it "looks up a nested element" do
    data = {
      "a_key" => "it's value",
      "nested_object" => {
        "first_key" => "first value",
        "second_key" => "second value"
      }
    }

    expect(parser.lookup("nested_object.first_key", data)).to eq("first value")
    expect(parser.lookup("nested_object.second_key", data)).to eq("second value")
    expect(parser.lookup("nested_object.inexistent_key", data)).to be_nil
    pending
    expect { parser.lookup("inexistent_key.inexistent_key", data) }.to raise_error
  end

  it "looks up the root element" do
    data = {
      "a_key" => "it's value",
      "nested_object" => {
        "first_key" => "first value",
        "second_key" => "second value"
      }
    }

    expect(parser.lookup("nested_object.first_key", data, data)).to eq("first value")
    expect(parser.lookup("first_key", data["nested_object"], data)).to eq("first value")
    expect(parser.lookup("$.nested_object.first_key", data["nested_object"], data)).to eq("first value")

    expect(parser.lookup("a_key", data, data)).to eq("it's value")
    expect(parser.lookup("nested_object.a_key", data, data)).to be_nil
    expect(parser.lookup("a_key", data["nested_object"], data)).to be_nil
    expect(parser.lookup("$.a_key", data["nested_object"], data)).to eq("it's value")
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
    expect(parsed_data).to eq(data['children'])
  end

end
