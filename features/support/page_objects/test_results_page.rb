class TestResultsPage < CdxPageBase
  set_url '/test_results/{?query*}'

  section :table, CdxTable, "table"
end
