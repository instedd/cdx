require 'spec_helper'

def build(input, options=nil)
  if options.nil?
    builder = CSVBuilder.new input
  else
    builder = CSVBuilder.new input, options
  end

  output = []
  builder.build output

  yield output
end

describe CSVBuilder do
  describe 'when user doesnt provide column_names' do
    it 'takes column names from first element' do
      build [{"foo" => 1, "bar" => 2}, {"baz" => 3, "etc" => 4}] do |output|
        expect(output[0]).to eq ["foo", "bar"]
      end
    end

    it 'is empty if there are no elements' do
      build [] do |output|
        expect(output).to be_empty
      end
    end

    it 'access columns with indifferent access' do
      build [{"foo" => 1, :bar => 2}] do |output|
        expect(output[1]).to eq([1,2])
      end
    end
  end

  describe 'when user provides column_names' do
    it 'includes column names even when there are no rows' do
      build [], column_names: ["hello", "world"] do |output|
        expect(output[0]).to eq ["hello", "world"]
        expect(output.length).to eq 1
      end
    end
  end
end
