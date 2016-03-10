module Reports
  class Devices < Base
    attr_reader :device_uuids

    def self.by_device(*args)
      new(*args).by_device
    end

    def self.total_devices(time_created)
      DeviceModel.where("created_at >= ?", time_created).count
    end

    def by_device
      filter['group_by'] = 'device.model,day(test.start_time)'
      total_count = TestResult.query(filter, current_user).execute['total_count']
      no_device_models = total_count
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

    def device_uuids
      results['tests'].index_by { |t| t['device.uuid'] }.keys
    end

    def process
      filter['group_by'] = 'device.uuid,day(test.start_time)'
      super
    end

    private

    def data_hash_day(dayname, devices)
      if devices
        device_results = devices.index_by {|d| d['device.uuid'] }
      end

      {
        label: dayname,
        values: device_uuids.map do |d|
          device_result = device_results && device_results[d]
          device_result ? device_result['count'] : 0
        end
      }
    end

    def data_hash_month(date, devices)
      if devices
        device_results = devices.index_by {|d| d['device.uuid'] }
      end

      {
        label: label_monthly(date),
        values: device_uuids.map do |d|
          device_result = device_results && device_results[d]
          device_result ? device_result['count'] : 0
        end
      }
    end

    def results_by_period(format)
      results['tests'].group_by do |t|
        Date.parse(t['test.start_time']).strftime(format)
      end
    end
  end
end
