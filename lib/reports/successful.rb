module Reports
  class Successful < Base
    attr_reader :test_names

    def process
      filter['test.status'] = 'success'
      filter['group_by'] = 'day(test.start_time),test.name'
      super
    end

    def test_names
      results['tests'].index_by { |t| t['test.name'] }.keys
    end

    private

    def data_hash_day(dayname, results)
      {
        label: dayname,
        values: test_names.map do |u|
          result = results && results[u]
          result ? count_total(result) : 0
        end
      }
    end

    def data_hash_month(date, results)
      {
        label: label_monthly(date),
        values: test_names.map do |u|
          result = results && results[u]
          result ? count_total(result) : 0
        end
      }
    end

    def day_results(format='%Y-%m-%d', key)
      results_by_period(format)[key].try do |r|
        r.group_by { |t| t['test.name'] }
      end
    end

    def month_results(format='%Y-%m', key)
      results_by_period(format)[key].try do |r|
        r.group_by { |t| t['test.name'] }
      end
    end
  end
end
