require 'spec_helper'

describe Cdx::Api::Elasticsearch::Query do
  describe '#grouped_by' do
    let(:params) { { :group_by => ['field1', 'field2', 'field3'] } }

    it 'returns an array with the group by fields of this query' do
      query = Cdx::Api::Elasticsearch::Query.new params
      expect(query.grouped_by.sort).to eq ['field1', 'field2', 'field3']
    end
  end
end