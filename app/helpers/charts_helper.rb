module ChartsHelper
  def query_tests_chart
    Reports::Base.process(current_user, @navigation_context).data
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
