module Reports
  class Errors < Base
    attr_accessor :users

    def self.by_code(*args)
      new(*args).by_code
    end

    def self.by_model(*args)
      new(*args).by_model
    end

    def self.by_not_successful(*args)
      new(*args).by_not_successful
    end

    def self.by_successful(*args)
      new(*args).by_successful
    end

    def by_code
      filter['test.status'] = 'error'
      total_count = TestResult.query(filter, current_user).execute['total_count']
      no_error_code = total_count
      filter['group_by'] = 'test.error_code'
      results = TestResult.query(filter, current_user).execute
      data = results['tests'].map do |test|
        no_error_code -= test['count']
        {
          label: test['test.error_code'],
          value: test['count']
        }
      end
      data << { label: 'Unknown', value: no_error_code } if no_error_code > 0
      data
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

    def by_successful
      filter['test.status'] = 'success'
      total_count = TestResult.query(filter, current_user).execute['total_count']
      no_error_code = total_count
      filter['group_by'] = 'test.status'
      results = TestResult.query(filter, current_user).execute
      data = results['tests'].map do |test|
      no_error_code -= test['count']
      {
        label: test['test.status'],
        value: test['count']
      }
      end
      data << { label: 'Unknown', value: no_error_code } if no_error_code > 0
      data
    end

    def by_not_successful
=begin
    status:
         type: enum
         searchable: true
         options:
           - invalid
           - error
           - no_result
           - success
           - in_progress
=end
      
      filter['test.status'] = 'invalid,error,no_result,in_progress'
        total_count = TestResult.query(filter, current_user).execute['total_count']
        no_error_code = total_count
        filter['group_by'] = 'test.status'
        results = TestResult.query(filter, current_user).execute
        data = results['tests'].map do |test|
        no_error_code -= test['count']
        {
          label: test['test.status'],
          value: test['count']
        }
      end


    def process
      filter['test.status'] = 'invalid,error,no_result,in_progress'
      filter['group_by'] = 'day(test.start_time),test.site_user'
      super
    end

    def users
      results['tests'].group_by { |t| t['test.site_user'] }.keys
    end

    private
    
    def data_hash_day(dayname, user_errors)
      {
        label: dayname,
        values: users.map do |u|
          user_result = user_errors && user_errors[u]
          user_result ? user_result['count'] : 0
        end
      }
    end

    def day_results(format='%Y-%m-%d', key)
      results_by_period(format)[key].try do |r|
        r.index_by { |t| t['test.site_user'] }
      end
    end

    def results_by_period(format)
      results['tests'].group_by {|t| t['test.start_time'] }
    end
  end
end
