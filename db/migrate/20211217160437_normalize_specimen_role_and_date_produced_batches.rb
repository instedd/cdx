class NormalizeSpecimenRoleAndDateProducedBatches < ActiveRecord::Migration
  def up
    Batch.find_each do |batch|
      unless batch.specimen_role.blank?
        specimen_role_ids_list = %w[b c e f g l o p q r v]
        specimen_role_id = batch.specimen_role[0].downcase
        batch.specimen_role = (specimen_role_ids_list.include? specimen_role_id) ? specimen_role_id : batch.specimen_role
      end

      batch.date_produced = if batch.date_produced.is_a?(String)
                               Time.strptime(batch.date_produced, Batch.date_format[:pattern]) rescue batch.date_produced
                             else
                               batch.date_produced
                             end

      batch.save
    end
  end

  def down
    # only udpate physical column in the database to not overwrite the value stored in core_fields
    connection.exec_update(<<-EOQ, "SQL", [[nil,'']])
      UPDATE  batches
      SET    date_produced = NULL
    EOQ
  end

end