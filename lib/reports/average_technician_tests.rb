module Reports
  class AverageTechnicianTests < Base

    def average_tests
      filter['group_by'] = "test.site_user,#{day_or_month}(test.start_time)"
      test_users_list=[]
      results = TestResult.query(@filter, current_user).execute
      results['tests'].each do |result|
        test_user = result['test.site_user']
        matched_test_user= test_users_list.find { |x| x[:site_user] == test_user }

        if matched_test_user
          matched_test_user[:total] += result['count']
          matched_test_user[:number_results] += 1
          matched_test_user[:peak] = result['count'] if matched_test_user[:peak] < result['count']
        else
          test_users_list << {
            site_user: test_user,
            total: result['count'],
            peak: result['count'],
            average: 0,
            number_results: 1
          }
        end
      end

      calculate_average(test_users_list)
      data = format_data(test_users_list)
      return data[0]
    end

    private
    def calculate_average(test_result_data)
      test_result_data.map do |test_user_data|
        if (test_user_data[:total]>0) && (test_user_data[:number_results]>0)
          test_user_data[:average] = test_user_data[:total] / test_user_data[:number_results]
        end
      end
    end
    
    def day_or_month
      number_of_days > 60 ? 'month' : 'day'
    end

    def format_data(test_result_data)
      chart_data=[]
      labels=[]
      peaks=[]
      averages=[]
      test_result_data.map do |test_user_data|
        labels << test_user_data[:site_user].truncate(12)
        peaks << test_user_data[:peak]
        averages << test_user_data[:average]
      end

      series =[]
      series << {label: 'Peak Tests', values: peaks}
      series << {label: 'Avg Tests', values: averages}
      chart_data << {labels: labels, series: series}

      return chart_data
    end

  end
end
