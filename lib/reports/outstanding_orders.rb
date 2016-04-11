module Reports
  class OutstandingOrders  < Base

    def latest_encounter
      @filter["group_by"]=nil
      encounters = Encounter.query(@filter, current_user).execute
      encounter_uuid_list=[]
      encounters["encounters"].each do |data|
        encounter = data["encounter"]
        person = full_name(encounter)
        encounter_uuid_list << {:test_order => encounter["uuid"],:date_ordered => Date.parse(encounter["start_time"]).strftime('%Y-%m-%d'),:test_result_encounter_end_time =>0,:outstanding => 0, :ordered_by => person}
      end
      #TODO , order results by time desc to remove a time check below: @filter['order_by']='-test.reported_time'
      if @filter['until'] != nil
        to_diff_time = @filter['until']
      else
        to_diff_time = Time.now
      end

      results = TestResult.query(filter, current_user).execute
      results["tests"].each do |result|
        encounter = result["encounter"]
        uuid = encounter["uuid"]
        matched_encounter= encounter_uuid_list.find {|x| x[:test_order] == uuid}
        if matched_encounter == nil
          Rails.logger.info("no matched encounter for #{uuid}")
        else
          end_time = encounter["end_time"]
       #   end_time = result["test"]["reported_time"]
          if (matched_encounter[:test_result_encounter_end_time]==0) || (matched_encounter[:test_result_encounter_end_time]>end_time)
            matched_encounter[:test_result_encounter_end_time] = end_time
            diff = (to_diff_time -  Time.parse(end_time.to_s))
            diff_days = (diff / 1.day).round
            matched_encounter[:outstanding] = diff_days if diff_days > 0
          end
        end
      end
      @outstanding_orders_size = encounter_uuid_list.length
     return encounter_uuid_list
    end

    private

    def full_name(encounter)
      return "" unless encounter['user_email']
      return User.where('email = ?', encounter['user_email']).first.full_name
    end

  end
end
