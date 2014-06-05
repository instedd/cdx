defmodule Institution do
  use Ecto.Model

  schema "institutions" do
    has_many(:subscribers, Subscriber)
    has_many(:laboratories, Laboratory)
    field :name
    field :user_id, :integer
  end

  def elasticsearch_index_name(institution_id) do
    "#{Elasticsearch.index_prefix}_#{institution_id}"
  end
end
