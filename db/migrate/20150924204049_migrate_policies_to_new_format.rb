class MigratePoliciesToNewFormat < ActiveRecord::Migration

  module NewActions
    CREATE_INSTITUTION = "institution:create"
    READ_INSTITUTION =   "institution:read"
    UPDATE_INSTITUTION = "institution:update"
    DELETE_INSTITUTION = "institution:delete"

    CREATE_INSTITUTION_LABORATORY = "institution:createLaboratory"
    CREATE_INSTITUTION_ENCOUNTER =  "institution:createEncounter"
    REGISTER_INSTITUTION_DEVICE =   "institution:registerDevice"

    READ_LABORATORY =   "laboratory:read"
    UPDATE_LABORATORY = "laboratory:update"
    DELETE_LABORATORY = "laboratory:delete"

    ASSIGN_DEVICE_LABORATORY = "laboratory:assignDevice"

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

    "#{PREFIX}:createInstitutionLaboratory" => NewActions::CREATE_INSTITUTION_LABORATORY,
    "#{PREFIX}:readLaboratory" => NewActions::READ_LABORATORY,
    "#{PREFIX}:updateLaboratory" => NewActions::UPDATE_LABORATORY,
    "#{PREFIX}:deleteLaboratory" => NewActions::DELETE_LABORATORY,

    "#{PREFIX}:createInstitutionEncounter" => NewActions::CREATE_INSTITUTION_ENCOUNTER,

    "#{PREFIX}:registerInstitutionDevice" => NewActions::REGISTER_INSTITUTION_DEVICE,
    "#{PREFIX}:readDevice" => NewActions::READ_DEVICE,
    "#{PREFIX}:updateDevice" => NewActions::UPDATE_DEVICE,
    "#{PREFIX}:deleteDevice" => NewActions::DELETE_DEVICE,
    "#{PREFIX}:assignDeviceLaboratory" => NewActions::ASSIGN_DEVICE_LABORATORY,
    "#{PREFIX}:regenerateDeviceKey" => NewActions::REGENERATE_DEVICE_KEY,
    "#{PREFIX}:generateActivationToken" => NewActions::GENERATE_ACTIVATION_TOKEN,
    "#{PREFIX}:queryTest" => NewActions::QUERY_TEST,
    "#{PREFIX}:reportMessage" => NewActions::REPORT_MESSAGE
  }

  def translate_action(action)
    ACTIONS_MAP[action] || action
  end

  def translate_resource(resource)
    resource =~ /\A#{PREFIX}:(.+)/ ? $1 : resource
  end

  def up

    # Do not calculate computed policies until we have migrated all policies
    Policy.skip_callback :save, :after, :update_computed_policies
    Policy.skip_callback :destroy, :after, :update_computed_policies
    Institution.skip_callback :create, :after, :grant_owner_policy

    # Wipe out all implicit policies
    Policy.where(granter_id: nil).where(name: 'implicit').delete_all

    # Migrate custom ones
    Policy.find_each do |policy|
      policy.definition['statement'].each do |statement|
        statement.delete('condition')
        statement.delete('effect')
        statement['action'] = statement['action'].map{|a| translate_action(a)} if statement['action'].kind_of?(Array)
        statement['resource'] = statement['resource'].map{|r| translate_resource(r)} if statement['resource'].kind_of?(Array)
      end
      policy.allows_implicit = true
      policy.save!
    end

    # Create new implicit ones
    User.find_each do |user|
      user.grant_implicit_policy
      user.institutions.each do |institution|
        user.grant_predefined_policy "owner", institution_id: institution.id
      end
    end

    # Calculate computed policies
    User.find_each do |user|
      ComputedPolicy.update_user(user)
    end

  end

end
