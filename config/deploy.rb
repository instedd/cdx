# config valid only for Capistrano 3.1
lock '3.1.0'

set :application, "cdp"
set :repo_url,  "git@github.com:instedd/cdp.git"

set :rvm_ruby_version, '2.0.0-p353'
set :rvm_type, :system
set :rails_env, 'production'
set :deploy_via, :remote_cache
set :user, 'ubuntu'

set :default_env, { 'TERM' => ENV['TERM'] }

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }
set :branch, ENV['REVISION'] || 'master'

# Default deploy_to directory is /var/www/my_app
set :deploy_to, "/u/apps/#{fetch(:application)}"

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
set :log_level, :debug
# set :log_level, :info

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
set :linked_files, %w{config/database.yml config/settings.yml config/guisso.yml}

# Default value for linked_dirs is []
# set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}
set :linked_dirs, %w{log public/nndd}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
set :keep_releases, 5

# role :web, "your web-server here"                          # Your HTTP server, Apache/etc
# role :app, "your app-server here"                          # This may be the same as your `Web` server
# role :db,  "your primary db-server here", :primary => true # This is where Rails migrations will run
# role :db,  "your slave db-server here"

set :assets_roles, [:web, :app]

namespace :foreman do
  desc 'Export the Procfile to Ubuntu upstart scripts'
  task :export do
    on roles(:app) do
      within current_path do
        execute :echo, "RAILS_ENV=production > .env"
        %w(PATH GEM_HOME GEM_PATH).each do |var|
          execute :rvm, %(#{fetch(:rvm_ruby_version)} do ruby -e 'puts "#{var}=\#{ENV["#{var}"]}"' >> .env)
        end
        execute :bundle, "exec rvmsudo foreman export upstart /etc/init -f Procfile -a #{fetch(:application)} -u `whoami` -p #{fetch(:port)} --concurrency=\"web=1\""
      end
    end
  end

  desc "Start the application services"
  task :start do
    on roles(:app) do
      execute "sudo start #{fetch(:application)}"
    end

  end
  desc "Stop the application services"
  task :stop do
    on roles(:app) do
      execute "sudo stop #{fetch(:application)}"
    end
  end

  desc "Restart the application services"
  task :restart do
    on roles(:app) do
      execute "sudo start #{fetch(:application)} || sudo restart #{fetch(:application)}"
    end
  end

  after "deploy:publishing", "foreman:export"    # Export foreman scripts
  after "deploy:restart", "foreman:restart"   # Restart application scripts
end

namespace :deploy do

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute :touch, release_path.join("tmp/restart.txt")
    end
  end

  desc 'Initialize Elasticsearch template'
  task :initialize_template do
    on roles(:app) do
      within current_path do
        with rails_env: :production do
          rake 'cdx_elasticserach:initialize_template'
        end
      end
    end
  end

  task :write_revision do
    on roles(:app) do
      within repo_path do
        execute :git, "describe --always > #{release_path}/REVISION"
      end
    end
  end

  task :write_version do
    on roles(:app) do
      within repo_path do
        if ENV['VERSION']
          execute :echo, "#{VERSION} > #{release_path}/VERSION"
        else
          execute :git, "describe --always > #{release_path}/VERSION"
        end
      end
    end
  end

  # before :restart, :migrate
  after :publishing, :write_revision
  after :publishing, :write_version
  after :publishing, :initialize_template
  after :publishing, :restart
end
