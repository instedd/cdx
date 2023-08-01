class FixSamplesMeasuredSignals < ActiveRecord::Migration[5.0]
  def up
    # make sure measured signals are always a float (the entity framework
    # deletes the attribute from the core_fields when it's nil):
    Sample
      .where("core_fields LIKE '%measured_signal%'")
      .preload(:sample_identifiers)
      .find_each do |sample|
        sample.measured_signal = sample.measured_signal.presence&.to_f
        sample.save(validate: false)
      end
  end

  def down
    # nothing to do
  end
end
