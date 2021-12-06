class MigrateDateProducedInBatches < ActiveRecord::Migration
  def up
    Batch.find_each do |batch|
      next if batch.date_produced.nil?
      batch.date_produced = if batch.date_produced.is_a?(String)
                              Time.strptime(value, Batch.date_format[:pattern]) rescue batch.date_produced
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