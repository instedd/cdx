module Reports
  class DeviceErrors < Base
    attr_reader :statuses

    def self.total_devices
      Device.count
    end

    def process
      filter['test.status'] = 'error'
      filter['group_by'] = 'month(test.start_time),device.model'
      super
    end

    def statuses
      results['tests'].index_by { |t| t['test.status'] }.keys
    end

    private

    def day_results(format, key)
      super
    end

    def results_by_period(format=nil)
      results['tests'].group_by { |t| t['test.start_time'] }
    end
  end
end
