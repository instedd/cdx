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

    def data_hash_day(dayname, day_results)
      {
        label: dayname,
        values: device_models.map do |u|
          device_model_result = date_results && date_results[u]
          device_model_result ? device_model_result['count'] : 0
        end
      }
    end

    def data_hash_month(date, month_results)
      {
        label: label_monthly(date),
        values: device_models.map do |u|
          device_model_result = month_results && month_results[u]
          device_model_result ? device_model_result['count'] : 0
        end
      }
    end

    def month_results(key)
      results_by_period[key].try { |r| r.index_by { |t| t['device.model'] } }
    end
  end
end
