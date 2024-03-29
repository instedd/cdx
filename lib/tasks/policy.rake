namespace :policy do

  desc "Make a user a superadmin"
  task :make_superadmin, [:user_id] => :environment do |task, args|
    unless args[:user_id]
      puts "Usage: $> rake policy:make_superadmin[{user_id}] RAILS_ENV={env}"
      exit
    end

    user = User.find args[:user_id]
    user.grant_superadmin_policy
  end

  desc "Regenerates computed policies for all users"
  task :calculate_computed => :environment do
    PoliciesMigrator.new.calculate_computed
    puts "\nSuccess!"
  end

  desc "Recreates implicit and owner policies for all users"
  task :implicit => :environment do
    PoliciesMigrator.new.update_implicit!
  end

  desc "Migrates policies to the latest format"
  task :migrate => :environment do
    PoliciesMigrator.new.run!
  end

  desc "Update policy for default roles from json.erbs"
  task :update_roles => :environment do
    PoliciesMigrator.new.update_roles
  end

  desc "Add Box permissions to predefined roles (one time migration)"
  task :add_box_permissions => :environment do
    PoliciesMigrator.new.add_resource_to_existing_roles("box", ["institution:createBox"])
  end

  desc "Add SamplesReport permissions to predefined roles (one time migration)"
  task :add_samples_report_permissions => :environment do
    Policy.transaction do
      PoliciesMigrator.new.add_resource_to_existing_roles("samplesReport", ["institution:createSamplesReport"])
    end
  end

  class PoliciesMigrator

    module NewActions
      CREATE_INSTITUTION = "institution:create"
      READ_INSTITUTION =   "institution:read"
      UPDATE_INSTITUTION = "institution:update"
      DELETE_INSTITUTION = "institution:delete"

      CREATE_INSTITUTION_SITE = "institution:createSite"
      CREATE_INSTITUTION_ENCOUNTER =  "institution:createEncounter"
      REGISTER_INSTITUTION_DEVICE =   "institution:registerDevice"

      READ_SITE =   "site:read"
      UPDATE_SITE = "site:update"
      DELETE_SITE = "site:delete"

      ASSIGN_DEVICE_SITE = "site:assignDevice"

      READ_DEVICE =   "device:read"
      UPDATE_DEVICE = "device:update"
      DELETE_DEVICE = "device:delete"

      REGENERATE_DEVICE_KEY =     "device:regenerateKey"
      GENERATE_ACTIVATION_TOKEN = "device:generateActivationToken"
      REPORT_MESSAGE =            "device:reportMessage"

      QUERY_TEST = "test:query"
    end

    PREFIX = "cdxp"

    ACTIONS_MAP = {
      "#{PREFIX}:createInstitution" => NewActions::CREATE_INSTITUTION,
      "#{PREFIX}:readInstitution" => NewActions::READ_INSTITUTION,
      "#{PREFIX}:updateInstitution" => NewActions::UPDATE_INSTITUTION,
      "#{PREFIX}:deleteInstitution" => NewActions::DELETE_INSTITUTION,

      "#{PREFIX}:createInstitutionLaboratory" => NewActions::CREATE_INSTITUTION_SITE,
      "#{PREFIX}:readLaboratory" => NewActions::READ_SITE,
      "#{PREFIX}:updateLaboratory" => NewActions::UPDATE_SITE,
      "#{PREFIX}:deleteLaboratory" => NewActions::DELETE_SITE,

      "#{PREFIX}:createInstitutionEncounter" => NewActions::CREATE_INSTITUTION_ENCOUNTER,

      "#{PREFIX}:registerInstitutionDevice" => NewActions::REGISTER_INSTITUTION_DEVICE,
      "#{PREFIX}:readDevice" => NewActions::READ_DEVICE,
      "#{PREFIX}:updateDevice" => NewActions::UPDATE_DEVICE,
      "#{PREFIX}:deleteDevice" => NewActions::DELETE_DEVICE,
      "#{PREFIX}:assignDeviceLaboratory" => NewActions::ASSIGN_DEVICE_SITE,
      "#{PREFIX}:regenerateDeviceKey" => NewActions::REGENERATE_DEVICE_KEY,
      "#{PREFIX}:generateActivationToken" => NewActions::GENERATE_ACTIVATION_TOKEN,
      "#{PREFIX}:queryTest" => NewActions::QUERY_TEST,
      "#{PREFIX}:reportMessage" => NewActions::REPORT_MESSAGE
    }

    def translate_action(action)
      ACTIONS_MAP[action] || action
    end

    def translate_resource(resource)
      resource = resource =~ /\A#{PREFIX}:(.+)/ ? $1 : resource
      resource.gsub("laboratory", "site")
    end

    def skip_callbacks
      Policy.skip_callback :save, :after, :update_computed_policies
      Policy.skip_callback :destroy, :after, :update_computed_policies
      Institution.skip_callback :create, :after, :grant_owner_policy
    end

    def delete_implicit
      puts "Deleting all implicit policies"
      Policy.where(granter_id: nil).delete_all
    end

    def calculate_computed
      puts "Recalculating computed policies for all users"
      User.find_each do |user|
        puts " #{user.email}"
        ComputedPolicy.update_user(user)
      end
    end

    def migrate_custom
      puts "Migrating custom policies"
      Policy.includes(:user).find_each do |policy|
        puts " #{policy.name} for user #{policy.user.email}"
        delegable = policy.definition.delete('delegable')
        policy.definition['statement'].each do |statement|
          statement.delete('condition')
          statement.delete('effect')
          statement['action'] = statement['action'].map{|a| translate_action(a)} if statement['action'].kind_of?(Array)
          statement['resource'] = statement['resource'].map{|r| translate_resource(r)} if statement['resource'].kind_of?(Array)
          statement['delegable'] ||= delegable
        end
        policy.allows_implicit = true
        policy.save!
      end
    end

    def run!
      skip_callbacks
      delete_implicit
      migrate_custom
      calculate_computed
      puts "\nSuccess!"
    end

    def update_implicit!
      skip_callbacks
      delete_implicit
      calculate_computed
      puts "\nSuccess!"
    end

    def update_roles
      puts "Updating institution roles..."
      Institution.all.each do |institution|
        puts institution.name
        roles = Policy.predefined_institution_roles(institution)
        roles.each do |role|
          existing_role = Role.find_or_create_by(
            institution: institution,
            name: role.name
          )
          old_policy = existing_role.policy
          existing_role.policy = role.policy
          existing_role.save!
          old_policy.try(:destroy)
        end
      end

      puts "Updating site roles..."
      Site.all.each do |site|
        puts site.name
        roles = Policy.predefined_site_roles(site)
        roles.each do |role|
          existing_role = Role.find_or_create_by(
            institution: site.institution,
            site: site,
            name: role.name
          )
          old_policy = existing_role.policy
          existing_role.policy = role.policy
          existing_role.save!
          old_policy.try(:destroy)
        end
      end

      puts "All policies updated"
      puts "Updating users' computed policies..."
      User.joins("INNER JOIN roles_users ON users.id = roles_users.user_id").each do |user|
        puts user.email
        user.computed_policies.destroy_all
        user.update_computed_policies
      end
    end

    def add_resource_to_existing_roles(resource_name, permissions)
      Institution.find_each do |institution|
        Policy.predefined_institution_roles(institution).each do |predefined_role|
          if role = Role.find_by(institution: institution, name: predefined_role.name)
            add_resource_permissions_to_existing_predefined_role(predefined_role, role, resource_name, permissions)
          end
        end
      end

      Site.find_each do |site|
        Policy.predefined_site_roles(site).each do |predefined_role|
          if role = Role.find_by(site: site, name: predefined_role.name)
            add_resource_permissions_to_existing_predefined_role(predefined_role, role, resource_name, permissions)
          end
        end
      end
    end

    private

    def add_resource_permissions_to_existing_predefined_role(predefined_role, actual_role, resource_name, permissions)
      puts "Updating #{actual_role.name} ..."

      search = ->(statements, resource) { statements.find { |s| s["resource"] == resource } }
      definition = actual_role.policy.definition
      actual_statements = definition["statement"]
      changed = false

      predefined_role.policy.definition["statement"].each do |statement|
        if statement["resource"].start_with?("#{resource_name}?")
          unless search.call(actual_statements, statement["resource"])
            actual_statements << statement
            changed = true
          end
        else
          permissions.each do |permission|
            next unless statement["action"].include?(permission)
            next unless actual = search.call(actual_statements, statement["resource"])

            unless actual["action"].include?(permission)
              actual["action"] << permission
              changed = true
            end
          end
        end
      end

      if changed
        actual_role.policy.allows_implicit = true
        actual_role.policy.save!
      end

      actual_role.policy.save
    end
  end
end
