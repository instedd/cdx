module ChartsHelper
  def query_tests_chart
    results = TestResult.query(contextual_query, current_user).execute

    results_by_day = results['tests'].group_by do |t|
      Date.parse(t['test']['start_time']).strftime('%Y-%m')
    end

    tests_chart_data = []
    11.downto(0).each do |i|
      date = Date.today - i.months
      date_key = date.strftime('%Y-%m')
      date_results = results_by_day[date_key]
      puts date_results
      tests_chart_data << {
        label: "#{I18n.t("date.abbr_month_names")[date.month]}#{date.month == 1 ? " #{date.strftime("%y")}" : ""}",
        values: [((date_results && date_results.count) || 0).to_i]
      }
    end
    return tests_chart_data
  end

  def contextual_query
    filter = default_query
    filter['institution.uuid'] = @navigation_context.institution.uuid if @navigation_context.institution
    filter["site.path"] = @navigation_context.site.uuid if @navigation_context.site
    filter
  end

  def default_query
    {
      'since' => (Date.today - 1.year).iso8601
    }
  end

  def tests_by_name
    query = contextual_query.merge({
      'group_by' => 'test.name'
    })

    results = TestResult.query(query, current_user).execute
    results['tests'].map do |test|
      {
        label: test['test.name'],
        value: test['count']
      }
    end
  end
end
