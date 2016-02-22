module Reports
  class AllTests < Base
    def self.by_name(*args)
      new(*args).by_name
    end

    def by_name
      filter['group_by'] = 'test.name'
      results = TestResult.query(filter, current_user).execute
      results['tests'].map do |test|
        {
          label: test['test.name'],
          value: test['count']
        }
      end
    end
  end
end
