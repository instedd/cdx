module Reports
  class Devices < Base
    attr_reader :device_uuids

    def self.total_devices(time_created)
      DeviceModel.where("created_at >= ?", time_created).count
    end

    def device_uuids
      results['tests'].index_by { |t| t['device.uuid'] }.keys
    end

    def process
      filter['group_by'] = 'device.uuid,day(test.start_time)'
      super
    end

    private

    def data_hash_day(dayname, device_results)
      {
        label: dayname,
        values: device_uuids.map do |d|
          device_result = device_results && device_results[d]
          device_result ? count_total(device_result) : 0
        end
      }
    end

    def data_hash_month(date, device_results)
      {
        label: label_monthly(date),
        values: device_uuids.map do |d|
          device_result = device_results && device_results[d]
          device_result ? count_total(device_result) : 0
        end
      }
    end

    def day_results(format='%Y-%m-%d', key)
      results_by_period(format)[key].try do |r|
        r.group_by { |t| t['device.uuid'] }
      end
    end

    def month_results(format='%Y-%m', key)
      results_by_period(format)[key].try do |r|
        r.group_by { |t| t['device.uuid'] }
      end
    end

    def results_by_period(format)
      results['tests'].group_by do |t|
        Date.parse(t['test.start_time']).strftime(format)
      end
    end
  end
end
