require 'spec_helper'

describe XmlMessageParser do

  let(:parser) { XmlMessageParser.new }

  let(:xml) do
    <<-XML
      <Message>
        <Patient name="Socrates" age="27"/>
        <SampleId>123</SampleId>
        <Result>FLU</Result>
        <Result>H1N1</Result>
      </Message>
    XML
  end

  let(:xml_with_children) do
    <<-XML
      <Messages>
        <Message>
          <Patient name="Socrates" age="27"/>
          <SampleId>123</SampleId>
          <Result>FLU</Result>
          <Result>H1N1</Result>
        </Message>
        <Message>
          <Patient name="Plato" age="33"/>
          <SampleId>456</SampleId>
        </Message>
      </Messages>
    XML
  end

  it 'should return root as data' do
    data = parser.load(xml)
    data.size.should eq(1)
    data.map(&:name).should eq(['Message'])
  end

  it 'should return root using a root path' do
    data = parser.load(xml_with_children, 'Messages')
    data.size.should eq(2)
    data.map(&:name).should eq(['Message'] * 2)
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
      <Messages>
        <Message>
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
        </Message>
        <Message>
          <Patient name="Plato" age="33"/>
          <SampleId>456</SampleId>
        </Message>
        <ManufacturerId>AcmeInc</ManufacturerId>
      </Messages>
    XML
  end

  it 'should lookup from the root element' do
    root = parser.load(complex_xml, 'Messages')
    data = root.first.xpath('Result[2]')
    parser.lookup("Name/text()", data, root.first).should eq('H1N1')
    # TODO: We shouldn't need the `..` here, but we're assuming there's always
    # a root element with elements inside
    parser.lookup("/../ManufacturerId/text()", data, root.first).should eq('AcmeInc')
  end

end
