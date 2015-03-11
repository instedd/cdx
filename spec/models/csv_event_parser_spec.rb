require 'spec_helper'

describe CSVEventParser do
  let(:user) {User.make}
  let(:institution) {Institution.make user_id: user.id}
  let(:device) {Device.make institution_id: institution.id}

  it "parses a single line CSV" do
    data = CSVEventParser.new.load <<-CSV.strip_heredoc
      error_code;result
      4002;negative
    CSV

    data.should eq([{
      error_code: '4002',
      result: 'negative'
    }.stringify_keys])
  end

  it "parses a multi line CSV" do
    data = CSVEventParser.new.load <<-CSV.strip_heredoc
      error_code;result
      4002;negative
      8002;positive
    CSV

    data.should eq([
      {error_code: '4002', result: 'negative'},
      {error_code: '8002', result: 'positive'}
    ].map(&:stringify_keys))
  end

  it "looks up a field given its path" do
    CSVEventParser.new.lookup('result', {'error_code' => '4002', 'result' => 'negative'}).should eq('negative')
  end

  it "does not support collections in lookup" do
    expect {
      CSVEventParser.new.lookup('results[*].result', {'error_code' => '4002', 'result' => 'negative'})
    }.to raise_error
  end


  it "does not support nested fields in lookup" do
    expect {
      CSVEventParser.new.lookup('error.error_code', {'error_code' => '4002', 'result' => 'negative'})
    }.to raise_error
  end

end
