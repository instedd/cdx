class Cdx::Api::Elasticsearch::CdxDocumentFormat
  def self.[](entity_name)
    case entity_name
    when "test_result"
      TestResult.new
    when "encounter"
      Encounter.new
    else
      raise "No document format for #{entity_name}"
    end
  end

  def indexed_field_name(cdx_field_name)
    cdx_field_name
  end

  def translate_entity(entity)
    entity
  end

  class TestResult < self
    def default_sort
      "test.reported_time"
    end
  end

  class Encounter < self
    def default_sort
      "encounter.uuid"
    end
  end
end
