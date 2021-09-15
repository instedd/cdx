namespace :samples do
  desc "normalize specimen_role values in Samples to be one of the options listed in fields.yml"
  task normalize_specimen_roles: :environment do
    Sample.find_each do |sample|
      unless sample.specimen_role.nil?
        sample.specimen_role = sample.specimen_role[0].downcase
        if not Sample::SPECIMEN_ROLES_IDS.include? sample.specimen_role
          sample.specimen_role = nil
        end
        sample.save
      end
    end
    puts "All samples processed"
  end
end
