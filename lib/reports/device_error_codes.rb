module Reports
  class DeviceErrorCodes < Base
    attr_reader :statuses

    def self.total_devices
      Device.count
    end

    def process
      filter['test.status'] = 'error'
 #      filter['group_by'] = 'month(test.start_time),device.model'
  
  #  filter['group_by'] = 'test.error_code,device.uuid,month(test.start_time)'
   filter['group_by'] = 'device.model,test.error_code'
   
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
