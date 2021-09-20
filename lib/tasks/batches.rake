namespace :batches do
  desc "normalize specimen_role values in Batches to be one of the options listed in fields.yml"
  task normalize_specimen_roles: :environment do
    Batch.find_each do |batch|
      next if batch.specimen_role.nil?

      specimen_role_id = batch.specimen_role[0].downcase
      batch.specimen_role = (Batch::SPECIMEN_ROLES_IDS.include? specimen_role_id) ? specimen_role_id : nil

      batch.save
    end
    puts "All Batches processed"
  end
end
