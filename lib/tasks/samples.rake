namespace :samples do
  desc "normalize specimen_role values in Samples to be one of the options listed in fields.yml"
  task normalize_specimen_roles: :environment do
    Sample.find_each do |sample|
      next if sample.specimen_role.nil?

      specimen_role_id = sample.specimen_role[0].downcase
      sample.specimen_role = (Sample::SPECIMEN_ROLES_IDS.include? specimen_role_id) ? specimen_role_id : nil

      sample.save
    end
    puts "All samples processed"
  end
end
