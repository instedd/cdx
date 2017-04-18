module Reports
  class Unsuccessful < Base
    attr_reader :statuses

    def process
      filter['test.status'] = 'invalid,error,no_result,in_progress'
      filter['group_by'] = 'day(test.start_time),test.status'
      super
    end

    def statuses
      results['tests'].index_by { |t| t['test.status'] }.keys
    end

    private

    def data_hash_day(dayname, results)
      {
        label: dayname,
        values: statuses.map do |u|
          result = results && results[u]
          result ? count_total(result) : 0
        end
      }
    end

    def data_hash_month(date, results)
      {
        label: label_monthly(date),
        values: statuses.map do |u|
          result = results && results[u]
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
