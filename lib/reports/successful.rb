module Reports
  class Successful < Base
    attr_reader :statuses

    def self.by_successful(*args)
      new(*args).by_successful
    end

    def by_successful
      filter['test.status'] = 'success'
      total_count = TestResult.query(filter, current_user).execute['total_count']
      no_error_code = total_count
      filter['group_by'] = 'test.status'
      results = TestResult.query(filter, current_user).execute
      data = results['tests'].map do |test|
      no_error_code -= test['count']
      {
        label: test['test.status'],
        value: test['count']
      }
      end
      data << { label: 'Unknown', value: no_error_code } if no_error_code > 0
      data
    end

    def process
      filter['test.status'] = options['test.status'] || 'success'
      filter['group_by'] = 'month(test.start_time),test.status'
      super
    end

    def statuses
      results['tests'].index_by { |t| t['test.status'] }.keys
    end

    private

    def data_hash_day(dayname, day_results)
      {
        label: dayname,
        values: statuses.map do |u|
          status_result = date_results && date_results[u]
          status_result ? status_result['count'] : 0
        end
      }
    end

    def data_hash_month(date, date_results)
      {
        label: label_monthly(date),
        values: statuses.map do |u|
          status_result = date_results && date_results[u]
          status_result ? status_result['count'] : 0
        end
      }
    end

    def month_results(key)
      results_by_period[key].try { |r| r.index_by { |t| t['test.status'] } }
    end
  end
end
