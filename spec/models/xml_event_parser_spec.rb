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

  let(:complex_xml) do
    <<-XML
      <Events>
        <Event>
          <Patient name="Socrates" age="27"/>
          <SampleId>123</SampleId>
          <Result>
            <Name>FLU</Name>
            <Code>flu</Code>
          </Result>
          <Result>
            <Name>H1N1</Name>
            <Code>h1n1</Code>
          </Result>
        </Event>
        <Event>
          <Patient name="Plato" age="33"/>
          <SampleId>456</SampleId>
        </Event>
        <ManufacturerId>AcmeInc</ManufacturerId>
      </Events>
    XML
  end

  it 'should lookup from the root element' do
    root = parser.load(complex_xml)
    data = root.first.xpath('Result[2]')
    parser.lookup("Name/text()", data, root).should eq('H1N1')
    # TODO: We shouldn't need the `..` here, but we're assuming there's always
    # a root element with elements inside
    parser.lookup("/../ManufacturerId/text()", data, root).should eq('AcmeInc')
  end

end
