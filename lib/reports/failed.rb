module Reports
  class Failed < Base
    attr_reader :total_tests, :failed_tests

    def process
      @total_tests ||= sum_total
      @failed_tests ||= sum_failed
      sort_pie
      return self
    end

    private

    def local_process
      @results = TestResult.query(filter, current_user).execute
    end

    def sort_pie
      data << { label: 'Successful', value: total_tests - failed_tests }
      data << { label: 'Failed', value: failed_tests }
    end

    def sum_total
      local_process
      results['total_count']
    end

    def sum_failed
      filter['test.status'] = 'invalid,error,no_result'
      local_process
      results['total_count']
    end
  end
end
