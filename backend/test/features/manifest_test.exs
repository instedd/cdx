defmodule ManifestTest do
  use Cdp.TestCase

  defp assert_manifest_application(mappings_json, data, expected) do
    manifest_json = """
                    {
                      "field_mapping" : #{mappings_json}
                    }
                    """
    manifest = JSEX.decode!(manifest_json)
    result = Manifest.apply(manifest, data)
    assert result == expected
  end

  test "applies simple manifest to indexed core field" do
    assert_manifest_application """
                    [{
                        "target_field": "assay_name",
                        "selector" : "assay/name",
                        "type" : "core"
                    }]
                    """,
                    %{"assay" => %{"name" => "GX4002"}},
                    %{indexed: %{"assay_name" => "GX4002"}, pii: %{}, custom: %{}}
  end

  test "applies simple manifest to pii core field" do
    assert_manifest_application """
                    [{
                        "target_field": "patient_name",
                        "selector" : "patient/name",
                        "type" : "core"
                    }]
                    """,
                    %{"patient" => %{"name" => "John"}},
                    %{indexed: %{}, pii: %{"patient_name" => "John"}, custom: %{}}
  end

  test "applies simple manifest to custom non-indexed field" do
    assert_manifest_application """
                    [{
                        "target_field": "temperature",
                        "selector" : "temperature",
                        "type" : "custom"
                    }]
                    """,
                    %{"temperature" => 20},
                    %{indexed: %{}, pii: %{}, custom: %{"temperature" => 20}}
  end
end
