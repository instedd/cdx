module Reports
  class Errors < Base
    def self.by_code(*args)
      new(*args).by_code
    end

    def by_code
      filter['test.status'] = 'error'
      total_count = TestResult.query(filter, current_user).execute['total_count']
      no_error_code = total_count
      filter['group_by'] = 'test.error_code'
      results = TestResult.query(filter, current_user).execute
      data = results['tests'].map do |test|
        no_error_code -= test['count']
        {
          label: test['test.error_code'],
          value: test['count']
        }
      end
      data << { label: 'Unknown', value: no_error_code } if no_error_code > 0
      data
    end

    def process
      filter['test.status'] = 'error'
      filter['group_by'] = 'month(test.start_time),test.site_user'
      super
    end

    def sort_by_month(cnt=11)
      users = results['tests'].index_by { |t| t['test.site_user'] }.keys
      cnt.downto(0).each do |i|
        date = Date.today - i.months
        date_key = date.strftime('%Y-%m')
        date_results = results_by_day[date_key].try { |r| r.index_by { |t| t['test.site_user'] } }
        data << {
          label: label_monthly(date),
          values: users.map do |u|
            user_result = date_results && date_results[u]
            user_result ? user_result['count'] : 0
          end
        }
      end
      return data, users
    end

    private

    def results_by_day
      results['tests'].group_by { |t| t['test.start_time'] }
    end
  end
end
