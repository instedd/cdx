module Reports
  class ModelErrors < Base
    attr_reader :device_models

    def process
      filter['test.status'] = 'error'
      filter['group_by'] = 'day(test.start_time),device.model'
      super
    end

    def device_models
      results['tests'].index_by { |t| t['device.model'] }.keys
    end

    private

    def data_hash_day(dayname, model_errors)
      {
        label: dayname,
        values: device_models.map do |u|
          model_error_result = model_errors && model_errors[u]
          model_error_result ? count_total(model_error_result) : 0
        end
      }
    end

    def data_hash_month(date, model_errors)
      {
        label: label_monthly(date),
        values: device_models.map do |u|
          model_error_result = model_errors && model_errors[u]
          model_error_result ? count_total(model_error_result) : 0
        end
      }
    end

    def day_results(format='%Y-%m-%d', key)
      results_by_period(format)[key].try do |r|
        r.group_by { |t| t['device.model'] }
      end
    end

    def month_results(format='%Y-%m', key)
      results_by_period(format)[key].try do |r|
        r.group_by { |t| t['device.model'] }
      end
    end
  end
end
