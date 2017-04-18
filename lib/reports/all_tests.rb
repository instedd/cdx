module Reports
  class AllTests < Base
    def self.by_name(*args)
      new(*args).by_name
    end

    attr_reader :statuses

    def statuses
      results['tests'].group_by { |t| t['test.status'] }.keys
    end

    def process
      filter['group_by'] = 'day(test.start_time),test.status'
      super
    end

    private

    def data_hash_day(dayname, test_results)
      {
        label: dayname,
        values: statuses.map do |u|
          result = test_results && test_results[u]
          result ? count_total(result) : 0
        end
      }
    end

    def data_hash_month(date, test_results)
      {
        label: label_monthly(date),
        values: statuses.map do |s|
          result = test_results && test_results[s]
          result ? count_total(result) : 0
        end
      }
    end

    def day_results(format='%Y-%m-%d', key)
      results_by_period(format)[key].try do |r|
        r.group_by { |t| t['test.status'] }
      end
    end

    def month_results(format='%Y-%m', key)
      results_by_period(format)[key].try do |r|
        r.group_by { |t| t['test.status'] }
      end
    end
  end
end
