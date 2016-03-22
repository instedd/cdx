module Reports
  class Site < Base
    def process
      filter['group_by'] = 'day(test.start_time),site.uuid'
      super
    end

    def sort_by_site
    end
  end
end
