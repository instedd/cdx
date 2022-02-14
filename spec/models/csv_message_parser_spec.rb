require 'spec_helper'

describe CSVMessageParser do
  let(:user) {User.make}
  let(:institution) {Institution.make user: user}
  let(:device) {Device.make institution: institution}

  it "parses a single line CSV" do
    data = CSVMessageParser.new.load <<-CSV.strip_heredoc
      error_code;result
      4002;negative
    CSV

    expect(data).to eq([{
      error_code: '4002',
      result: 'negative'
    }.stringify_keys])
  end

  it "parses a multi line CSV" do
    data = CSVMessageParser.new.load <<-CSV.strip_heredoc
      error_code;result
      4002;negative
      8002;positive
    CSV

    expect(data).to eq([
      {error_code: '4002', result: 'negative'},
      {error_code: '8002', result: 'positive'}
    ].map(&:stringify_keys))
  end

  it "skips empty lines in multi line CSV" do
    data = CSVMessageParser.new.load <<-CSV

error_code;result
4002;negative
8002;positive

CSV

    expect(data).to eq([
      {error_code: '4002', result: 'negative'},
      {error_code: '8002', result: 'positive'}
    ].map(&:stringify_keys))
  end

  it "looks up a field given its path" do
    expect(CSVMessageParser.new.lookup('result', {'error_code' => '4002', 'result' => 'negative'})).to eq('negative')
  end

  it "does not support collections in lookup" do
    expect {
      CSVMessageParser.new.lookup('results.result', {'error_code' => '4002', 'result' => 'negative'})
    }.to raise_error(RuntimeError, 'path nesting is unsupported for CSV Messages')
  end

  it "does not support nested fields in lookup" do
    expect {
      CSVMessageParser.new.lookup('error.error_code', {'error_code' => '4002', 'result' => 'negative'})
    }.to raise_error(RuntimeError, 'path nesting is unsupported for CSV Messages')
  end

end
