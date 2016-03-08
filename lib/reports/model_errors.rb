module Reports
  class ModelErrors < Base
    attr_reader :device_models

    def self.by_model(*args)
      new(*args).by_model
    end

    def by_model
      filter['test.status'] = 'error'
      total_count = TestResult.query(filter, current_user).execute['total_count']
      no_error_code = total_count
      filter['group_by'] = 'device.model'
      results = TestResult.query(filter, current_user).execute
      data = results['tests'].map do |test|
        no_error_code -= test['count']
        {
          label: test['device.model'],
          value: test['count']
        }
      end
      data << { label: 'Unknown', value: no_error_code } if no_error_code > 0
      data
    end


    def process
      filter['test.status'] = 'error'
      filter['group_by'] = 'month(test.start_time),device.model'
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
