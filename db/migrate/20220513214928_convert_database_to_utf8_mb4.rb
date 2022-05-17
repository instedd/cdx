class ConvertDatabaseToUtf8Mb4 < ActiveRecord::Migration
  def up
    connection.execute "ALTER DATABASE CHARACTER SET 'utf8mb4' COLLATE 'utf8mb4_unicode_520_ci';"
    
    %w{
      alert_condition_results
      alert_histories
      alert_recipients
      alerts
      alerts_conditions
      alerts_devices
      alerts_sites
      assay_attachments
      assay_files
      batches
      computed_policies
      computed_policy_exceptions
      conditions
      conditions_manifests
      device_commands
      device_logs
      device_messages
      device_messages_test_results
      device_models
      devices
      encounters
      file_messages
      filters
      identities
      institutions
      loinc_codes
      manifests
      notes
      oauth_access_grants
      oauth_access_tokens
      oauth_applications
      old_passwords
      patients
      pending_institution_invites
      policies
      qc_infos
      recipient_notification_histories
      roles
      roles_users
      sample_identifiers
      sample_transfers
      samples
      sites
      ssh_keys
      subscribers
      test_result_parsed_data
      test_results
      transfer_packages
      users
    }.each { |table_name|
      connection.execute "ALTER TABLE `#{table_name}` CONVERT TO CHARACTER SET 'utf8mb4' COLLATE 'utf8mb4_unicode_520_ci';"
    }
  end

  def down
    # Nothing to do since there's no way of knowing the previous charset/collation
  end
end
