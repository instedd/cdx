module Reports
  class AverageSiteTests < Base
    def process
      filter['group_by'] = "site.uuid,#{day_or_month}(test.reported_time)"
      super
    end

    def show
      results['tests'].each do |result|
        data << {
          site: lookup_site(result['site.uuid']),
          peak: calculate_peak(result['site.uuid']),
          average: calculate_average(result)
        }
      end
      data
    end

    private

    def calculate_average(result)
      period = number_of_months > 1 ? number_of_months : number_of_days
      (result['count'].to_f / period)
    end

    def calculate_peak(uuid)
      peak_value = 0
      tests = period_results['tests'].group_by do |t|
        Date.parse(t['test']['start_time']).strftime(format)
      end
      tests.each do |test_group|
        cnt = test_group[1].select { |site| site['uuid'] = uuid }.count
        peak_value = cnt if cnt > peak_value
      end
      peak_value
    end

    def format
      day_or_month == 'day' ? '%Y-%m-%d' : '%Y-%m'
    end

    def lookup_site(uuid)
      site = ::Site.where(uuid: uuid).first
      return site.name if site
    end

    def period_results
      filter.delete('group_by')
      @period_results ||= TestResult.query(filter, current_user).execute
    end
  end
end
