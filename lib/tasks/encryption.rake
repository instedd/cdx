namespace :encryption do

  task :reencrypt => :environment do
    raise "Please specify OLD_SECRET_KEY and NEW_SECRET_KEY environment variables" if (ENV['OLD_SECRET_KEY'].blank? || ENV['NEW_SECRET_KEY'].blank?)

    reencrypt = proc do |str|
      MessageEncryption.reencrypt str,
        old_key: ENV['OLD_SECRET_KEY'],
        old_salt: ENV['OLD_SALT'] || MessageEncryption::DEFAULT_SALT,
        old_iv: ENV['OLD_IV'] || MessageEncryption::DEFAULT_IV,
        new_key: ENV['NEW_SECRET_KEY'],
        new_salt: ENV['NEW_SALT'] || MessageEncryption::DEFAULT_SALT,
        new_iv: ENV['NEW_IV'] || MessageEncryption::DEFAULT_IV
    end

    puts "Reencrypting raw device messages"
    DeviceMessage.find_each do |device_message|
      device_message.update_column :raw_data, reencrypt.call(device_message.raw_data)
    end

    [TestResult, Sample, Encounter, Patient].each do |klazz|
      puts "Reencrypting sensitive data for #{klazz.name.pluralize}"
      klazz.find_each do |entity|
        entity.update_column :sensitive_data, reencrypt.call(entity.sensitive_data)
      end
    end
  end

end
