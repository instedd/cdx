class NormalizeSpecimenRoleAndDateProducedSamples < ActiveRecord::Migration
  def up
    Sample.find_each do |sample|
      unless sample.specimen_role.blank?
        specimen_role_id = sample.specimen_role[0].downcase
        sample.specimen_role = (Sample.specimen_role_ids_list.include? specimen_role_id) ? specimen_role_id : sample.specimen_role
      end

      sample.date_produced = if sample.date_produced.is_a?(String)
                               Time.strptime(sample.date_produced, Sample.date_format[:pattern]) rescue sample.date_produced
                             else
                               sample.date_produced
                             end

      sample.save
    end
  end

  def down
    # only udpate physical column in the database to not overwrite the value stored in core_fields
    connection.exec_update(<<-EOQ, "SQL", [[nil,'']])
      UPDATE  samples
      SET    specimen_role = ''
    EOQ
  end

end