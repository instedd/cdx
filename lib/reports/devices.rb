module Reports
  class Devices < Base
    def self.by_device(*args)
      new(*args).by_device
    end

    def by_device
     filter = {'test.reported_time_since' => Time.now - 1.week,'test.reported_time_until' => Time.now,"group_by" => "device.model,day(test.reported_time)" }
        
      total_count = TestResult.query(filter, current_user).execute['total_count']
      no_device_models = total_count
      filter['group_by'] = 'device.model'
      results = TestResult.query(filter, current_user).execute
      data = results['tests'].map do |test|
        no_device_models -= test['count']
        {
          label: test['device.model'],
          value: test['count']
        }
      end
      data << { label: 'Unknown', value: no_device_models } if no_device_models > 0
      data
    end

    def process
      filter['group_by'] = 'month(test.reported_time),device.model'
      super
    end

    def sort_by_month
      device_models = results['tests'].index_by { |t| t['device.model'] }.keys
      11.downto(0).each do |i|
        date = Date.today - i.months
        date_key = date.strftime('%Y-%m')
        date_results = results_by_day[date_key].try { |r| r.index_by { |t| t['device.model'] } }
        data << {
          label: label_monthly(date),
          values: device_models.map do |u|
            device_model_result = date_results && date_results[u]
            device_model_result ? device_model_result['count'] : 0
          end
        }
      end
      return data, device_models
    end

    private

    def results_by_day
      results['tests'].group_by { |t| t['test.reported_time'] }
    end
  end
end
