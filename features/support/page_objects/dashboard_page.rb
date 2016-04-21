class DashboardPage < CdxPageBase
  set_url '/dashboards/index{?query*}'

  section :tests_run, TestsRun, '#tests_run'
end
