namespace :db do

  desc "Copies master development database, or specified by SOURCE env param, into current branch name only if it does not exist"
  task :clone do
    config = Rails.application.config.database_configuration[Rails.env]
    source_db = ENV['SOURCE'].presence || 'cdp_development'
    target_db = config['database']
    mysql_opts =  "-u #{config['username']} "
    mysql_opts << "--password=\"#{config['password']}\" " if config['password'].presence

    `mysqlshow #{mysql_opts} #{target_db.gsub('_', '\\\\\_')}`
    raise "Target database #{target_db} already exists" if $?.to_i == 0

    `mysqlshow #{mysql_opts} #{source_db.gsub('_', '\\\\\_')}`
    raise "Source database #{source_db} not found" if $?.to_i != 0

    puts "Creating empty database #{target_db}"
    `mysql #{mysql_opts} -e "CREATE DATABASE #{target_db}"`

    puts "Copying #{source_db} into #{target_db}"
    `mysqldump #{mysql_opts} #{source_db} | mysql #{mysql_opts} #{target_db}`
  end

end
