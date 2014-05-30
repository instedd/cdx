defmodule TestResult do
  use Ecto.Model
  import Ecto.Query

  queryable "test_results" do
    belongs_to(:device, Device)
    field :created_at, :datetime
    field :updated_at, :datetime
    field :uuid
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
      {:analytes, :nested, [
        {:result, :multi_field, [{"result", :wildcard}]},
        {:condition, :string, [{"condition", :wildcard}]},
      ]},
    ]
  end

  def pii?(field) do
    Enum.member? sensitive_fields, binary_to_atom(field)
  end

  def pii_of(test_result_uuid) do
    Enum.into([{"uuid", test_result_uuid}, {"pii", find_by_uuid_in_postgres(test_result_uuid).sensitive_data}], %{})
  end

  def custom_fields_of(test_result_uuid) do
    Enum.into([{"uuid", test_result_uuid}, {"custom_fields", JSEX.decode!(find_by_uuid_in_postgres(test_result_uuid).custom_fields)}], %{})
  end

  def find_by_uuid_in_postgres(test_result_uuid) do
    query = from t in TestResult,
      where: t.uuid == ^test_result_uuid,
      select: t
    [postgres_test_result] = Repo.all(query)
    decrypt(postgres_test_result)
  end

  def encrypt(test_result) do
    test_result = :crypto.rc4_encrypt(encryption_key, JSEX.encode!(test_result.sensitive_data))
      |> test_result.sensitive_data
    test_result.raw_data(:crypto.rc4_encrypt(encryption_key, test_result.raw_data))
  end

  def decrypt(test_result) do
    test_result = :crypto.rc4_encrypt(encryption_key, test_result.sensitive_data)
      |> JSEX.decode!
      |> test_result.sensitive_data

    test_result.raw_data(:crypto.rc4_encrypt(encryption_key, test_result.raw_data))
  end

  defp encryption_key do
    "some secure key"
  end
end
