module Reports
  class Base
    def self.process(*args)
      new(*args).process
    end

    attr_reader :current_user, :context, :data, :date_results, :end_date
    attr_reader :filter, :options, :results, :start_date

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
      nod = number_of_days
      nod.downto(0).each do |i|
        day = Date.parse(end_date) - i.days
        key = day.strftime('%Y-%m-%d')
        data << data_hash_day(day, day_results('%Y-%m-%d', key))
      end
      return self
    end

    def sort_by_hour(cnt=23)
      hour_results = results_by_period('%H')
      cnt.downto(0) do |i|
        now = (Time.now - i.hours)
        hourname = now.strftime('%H')
        data << {
          label: hourname,
          values: [hour_results ? hour_results[hourname].count : 0]
        }
      end
      return data
    end

    def sort_by_month
      nom = number_of_months.abs - 1
      nom.downto(0).each do |i|
        date = Date.parse(end_date) - i.months
        date_key = date.strftime('%Y-%m')
        data << data_hash_month(date, month_results(date_key))
      end
      return self
    end

    def start_date
      return options['range']['start_time']['gte'] if options['range']
      return options['since'] if options['since']
      return report_since
    end

    def end_date
      return options['range']['start_time']['lte'] if options['range']
      Date.today.iso8601
    end

    def number_of_days
      Date.parse(end_date).jd - Date.parse(start_date).jd
    end

    def number_of_months
      sd = Date.parse(start_date)
      ed = Date.parse(end_date)
      (ed.year * 12 + ed.month) - (sd.year * 12 + sd.month)
    end

    private

    def data_hash_day(dayname, day_results)
      {
        label: label_daily(dayname),
        values: [day_results ? day_results.count : 0]
      }
    end

    def data_hash_month(date, date_results)
      {
        label: label_monthly(date),
        values: [date_results ? date_results.count : 0]
      }
    end

    def date_constraints
      options['date_range'] ? report_between : report_since
    end

    def day_results(format, key)
      results_by_period(format)[key]
    end

    def label_daily(day)
      day.strftime('%d/%m')
    end

    def label_monthly(date)
      "#{I18n.t('date.abbr_month_names')[date.month]}#{date.month == 1 ? " #{date.strftime('%y')}" : ""}"
    end

    def month_results(period)
      results_by_period('%Y-%m')[period]
    end

    def report_between
      filter['range'] = options['date_range']
    end

    def report_since
      filter['since'] = options['since'] || (Date.today - 1.year).iso8601
    end

    def results_by_period(format = '%Y-%m')
      results['tests'].group_by do |t|
        if(format == '%H')
          DateTime.strptime(t['test']['start_time'], '%Y-%m-%dT%H:%M:%S')
        else
          begin
            Date.parse(t['test']['start_time']).strftime(format)
          rescue Exception
          end
        end
      end
    end

    def setup
      site_or_institution
      date_constraints
      ignore_qc
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
      results['tests'].index_by { |t| t['test.site_user'] }.keys
    end
  end
end
