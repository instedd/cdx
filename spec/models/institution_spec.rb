require 'spec_helper'

describe Institution do
  let(:user) {User.make}
  let(:institution) {Institution.make user_id: user.id}

  it "should ensure the creation of the elasticsearch index" do
    institution
    expect { institution.save }.not_to raise_error

    client = Cdx::Api.client
    expect { client.indices.refresh index: institution.elasticsearch_index_name }.not_to raise_error
  end
end
