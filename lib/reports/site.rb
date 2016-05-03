module Reports
  class Site < Base
    def process
      filter['group_by'] = 'day(test.start_time),site.uuid'
      super
    end

    def sites
      site_uuids.inject({}) { |h, uuid| h[uuid] = lookup_site(uuid); h }
    end

    def sort_by_site
      site_results.each do |uuid, results|
        data << [sites[uuid], count_total(results)]
      end
      return self
    end

    private

    def lookup_site(uuid)
      site = ::Site.where(uuid: uuid).first
      return site.name if site
    end

    def site_results
      results['tests'].group_by { |t| t['site.uuid'] }
    end

    def site_uuids
      site_results.keys
    end
  end
end
