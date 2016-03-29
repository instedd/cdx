module Reports
  class DeviceErrorCodes < Base
    attr_reader :statuses

    def self.total_devices
      Device.count
    end

    def process
      filter['test.status'] = 'error'  
      filter['group_by'] = 'device.uuid,test.error_code,location.id'
      super
    end
    
    def get_device_location_details
      data = results['tests'].map do |result|
      {
        device: Device.where(uuid: result["device.uuid"]).pluck(:name)[0],
        error_code: result["test.error_code"],
        count: result["count"],
        location: Site.where(location_geoid: result["location.id"]).pluck(:name)
      }
      end
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
