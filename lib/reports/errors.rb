module Reports
  class Errors < Base
    attr_accessor :error_codes

    def process
      filter['test.status'] = 'error'
      filter['group_by'] = 'day(test.start_time),test.error_code'
      super
    end

    def error_codes
      results['tests'].group_by { |t| t['test.error_code'] }.keys
    end

    private

    def data_hash_day(dayname, errors)
      {
        label: dayname,
        values: error_codes.map do |u|
          result = errors && errors[u]
          result ? count_total(result) : 0
        end
      }
    end

    def data_hash_month(date, errors)
      {
        label: label_monthly(date),
        values: error_codes.map do |u|
          result = errors && errors[u]
          result ? count_total(result) : 0
        end
      }
    end

    def day_results(format='%Y-%m-%d', key)
      results_by_period(format)[key].try do |r|
        r.group_by { |t| t['test.error_code'] }
      end
    end

    def month_results(format='%Y-%m', key)
      results_by_period(format)[key].try do |r|
        r.group_by { |t| t['test.error_code'] }
      end
    end
  end
end
