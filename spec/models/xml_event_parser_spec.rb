require 'spec_helper'

describe XmlEventParser do

  let(:parser) { XmlEventParser.new }
  let(:xml) do
    <<-XML
      <Events>
        <Event>
          <Patient name="Socrates" age="27"/>
          <SampleId>123</SampleId>
          <Result>FLU</Result>
          <Result>H1N1</Result>
        </Event>
        <Event>
          <Patient name="Plato" age="33"/>
          <SampleId>456</SampleId>
        </Event>
      </Events>
    XML
  end

  it 'should return root children as data' do
    data = parser.load(xml)
    data.size.should eq(2)
    data.map(&:name).should eq(['Event'] * 2)
  end

  it 'should query attributes' do
    data = parser.load(xml).first
    parser.lookup("Patient/@name", data).should eq('Socrates')
  end

  it 'should query text inside element' do
    data = parser.load(xml).first
    parser.lookup("SampleId/text()", data).should eq('123')
  end

  it 'should query multiple results' do
    data = parser.load(xml).first
    parser.lookup("Result/text()", data).should eq(['FLU', 'H1N1'])
  end

end
