class CDPDocumentFormat
  def default_sort
    "test.reported_time"
  end

  def indexed_field_name(cdp_field_name)
    cdp_field_name
  end

  def translate_test(test)
    test
  end
end
