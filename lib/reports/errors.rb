module Reports
  class Errors < Base
    attr_accessor :users

    def process
      filter['test.status'] = 'invalid,error,no_result,in_progress'
      filter['group_by'] = 'day(test.start_time),test.site_user'
      super
    end

    def users
      results['tests'].group_by { |t| t['test.site_user'] }.keys
    end

    private

    def data_hash_day(dayname, user_errors)
      {
        label: dayname,
        values: users.map do |u|
          user_result = user_errors && user_errors[u]
          user_result ? count_total(user_result) : 0
        end
      }
    end

    def data_hash_month(date, user_errors)
      {
        label: label_monthly(date),
        values: users.map do |u|
          user_result = user_errors && user_errors[u]
          user_result ? count_total(user_result) : 0
        end
      }
    end

    def day_results(format='%Y-%m-%d', key)
      results_by_period(format)[key].try do |r|
        r.group_by { |t| t['test.site_user'] }
      end
    end

    def month_results(format='%Y-%m', key)
      results_by_period(format)[key].try do |r|
        r.group_by { |t| t['test.site_user'] }
      end
    end
  end
end
