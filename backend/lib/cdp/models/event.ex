defmodule Event do
  use Ecto.Model
  import Ecto.Query

  schema "events" do
    belongs_to(:device, Device)
    field :created_at, :datetime
    field :updated_at, :datetime
    field :uuid
    field :event_id
    field :custom_fields
    field :raw_data, :binary
    field :sensitive_data, :binary
  end

  def sensitive_fields do
    [
      :patient_id,
      :patient_name,
      :patient_telephone_number,
      :patient_zip_code,
    ]
  end

  def searchable_fields do
    [
      {:created_at, :date, [
        {"since", {:range, [:from, {:include_lower, true}]}},
        {"until", {:range, [:to, {:include_lower, true}]}}
      ]},
      {:event_id, :integer, [{"event_id", :match}]},
      {:device_uuid, :string, [{"device", :match}]},
      {:laboratory_id, :integer, [{"laboratory", :match}]},
      {:institution_id, :integer, [{"institution", :match}]},
      {:location_id, :integer, []},
      {:parent_locations, :integer, [{"location", :match}]},
      {:age, :integer, [
        {"age", :match},
        {"min_age", {:range, [:from, {:include_lower, true}]}},
        {"max_age", {:range, [:to, {:include_upper, true}]}},
      ]},
      {:assay_name, :string, [{"assay_name", :wildcard}]},
      {:device_serial_number, :string, []},
      {:gender, :string, [{"gender", :wildcard}]},
      {:uuid, :string, [{"uuid", :match}]},
      {:start_time, :date, []},
      {:system_user, :string, []},
      {:results, :nested, [
        {:result, :multi_field, [{"result", :wildcard}]},
        {:condition, :string, [{"condition", :wildcard}]},
      ]},
    ]
  end

  def pii?(field) do
    Enum.member? sensitive_fields, binary_to_atom(field)
  end

  def pii_of(event_uuid) do
    Enum.into([{"uuid", event_uuid}, {"pii", find_by_uuid_in_postgres(event_uuid).sensitive_data}], %{})
  end

  def custom_fields_of(event_uuid) do
    Enum.into([{"uuid", event_uuid}, {"custom_fields", JSEX.decode!(find_by_uuid_in_postgres(event_uuid).custom_fields)}], %{})
  end

  def find_by_uuid_in_postgres(event_uuid) do
    query = from t in Event,
      where: t.uuid == ^event_uuid,
      select: t
    [postgres_event] = Repo.all(query)
    decrypt(postgres_event)
  end

  def encrypt(event) do
    event = :crypto.rc4_encrypt(encryption_key, JSEX.encode!(event.sensitive_data))
      |> event.sensitive_data
    event.raw_data(:crypto.rc4_encrypt(encryption_key, event.raw_data))
  end

  def decrypt(event) do
    event = :crypto.rc4_encrypt(encryption_key, event.sensitive_data)
      |> JSEX.decode!
      |> event.sensitive_data

    event.raw_data(:crypto.rc4_encrypt(encryption_key, event.raw_data))
  end

  defp encryption_key do
    "some secure key"
  end
end
