module Reports
  class Base
    def self.process(*args)
      new(*args).process
    end

    attr_reader :current_user, :context, :data, :filter, :options, :results

    def initialize(current_user, context, options={})
      @filter ||= {}
      @current_user = current_user
      @context = context
      @data = []
      @options = options
      setup
    end

    def process
      @results = TestResult.query(filter, current_user).execute
      return self
    end

    def sort_by_day
      6.downto(0).each do |i|
        day = Date.today - i.days
        dayname = day.strftime('%A')
        key = day.strftime('%Y-%m-%d')
        day_results = results_by_period('%Y-%m-%d')[key]
        data << {
          label: dayname,
          values: [day_results ? day_results.count : 0]
        }
      end
      return data
    end
    
    def sort_by_hour
      hour_results = results_by_period('%H')
      23.downto(0) do |i|
        now = (Time.now - i.hours)
        hourname = now.strftime('%H')
        hourname = "0"+hourname if hourname.length==1
        data << {
          label: hourname,
          values: [hour_results ? hour_results[hourname].count : 0]
        }
      end
      return data
    end

    def sort_by_month
      11.downto(0).each do |i|
        date = Date.today - i.months
        date_key = date.strftime('%Y-%m')
        date_results = results_by_period[date_key]
        data << {
          label: label_monthly(date),
          values: [date_results ? date_results.count : 0]
        }
      end
      return data
    end

    private

    def label_monthly(date)
      "#{I18n.t('date.abbr_month_names')[date.month]}#{date.month == 1 ? " #{date.strftime('%y')}" : ""}"
    end

    def report_between
      filter['range'] = options['date_range']
    end

    def report_since
      filter['since'] = options['since'] || (Date.today - 1.year).iso8601
    end

    def results_by_period(format = '%Y-%m')
      results['tests'].group_by do |t|      
        if format == "%Y-%m-%d"
          Date.parse(t['test']['start_time']).strftime(format) 
        else  
          DateTime.strptime(t['test']['start_time'], '%Y-%m-%dT%H:%M:%S').strftime("%H") 
        end
      end
    end

    def setup
      site_or_institution
      date_constraints
      ignore_qc
    end

    def date_constraints
      options['date_range'] ? report_between : report_since
    end

    def site_or_institution
      filter['institution.uuid'] = context.institution.uuid if context.institution
      filter['site.path'] = context.site.uuid if context.site
    end

    def ignore_qc
      # TODO post mvp: should generate list of all types but qc, or support query by !=
      filter["test.type"] = "specimen"
    end

    def users
      results['tests'].group_by { |t| t['test.start_time'] }
    end
  end
end
