namespace :batches do
  desc "normalize specimen_role values in Batches to be one of the options listed in fields.yml"
  task normalize_specimen_roles: :environment do
    Batch.find_each do |batch|
      unless batch.specimen_role.nil?
        batch.specimen_role = batch.specimen_role[0].downcase
        if not Batch::SPECIMEN_ROLES_IDS.include? batch.specimen_role
          batch.specimen_role = nil
        end
        batch.save
      end
    end
    puts "All Batches processed"
  end
end
