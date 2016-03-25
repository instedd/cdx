module Reports
  class Grouped < Base

    def self.method_missing(sym, *args, &block)
      return new(*args).grouped_by($1.to_sym) if /^by_(.*)/.match(sym.to_s) && groupings[$1.to_sym]
      super
    end

    def grouped_by(symbol)
      groupings = Reports::Grouped.groupings
      filter['group_by'] = groupings[symbol][0]
      filter['test.status'] = groupings[symbol][1] if groupings[symbol][1]
      results = TestResult.query(filter, current_user).execute
      total_count = results['total_count']
      no_error_code = total_count
      data = results['tests'].map do |test|
        no_error_code -= test['count']
        {
          label: label(test[groupings[symbol][0]], symbol),
          value: test['count']
        }
      end
      data << { label: 'Unknown', value: no_error_code } if no_error_code > 0
      data
    end

    private

    def self.groupings
      {
        device: ['device.uuid'],
        error_code: ['test.error_code','invalid,error,no_result,in_progress'],
        model: ['device.model','error'],
        status: ['test.status'],
        successful: ['test.name','success'],
        unsuccessful: ['test.status','invalid,error,no_result,in_progress']
      }
    end

    def label(uuid, symbol)
      return lookup_device(uuid) if symbol == :device
      uuid
    end
  end
end