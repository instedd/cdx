# config valid only for Capistrano 3.1
lock '3.1.0'

set :application, "cdp"
set :repo_url,  "git@bitbucket.org:instedd/cdp.git"

set :rvm_ruby_version, '2.0.0-p353'
set :rvm_type, :system
set :rails_env, 'production'
set :scm, :git
set :deploy_via, :remote_cache
set :user, 'ubuntu'
set :deploy_to, "/u/apps/#{fetch(:application)}"

set :default_env, { 'TERM' => ENV['TERM'] }

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }

# Default deploy_to directory is /var/www/my_app
# set :deploy_to, '/var/www/my_app'

# Default value for :scm is :git
# set :scm, :git

# Default value for :format is :pretty
# set :format, :pretty

# Default value for :log_level is :debug
# set :log_level, :debug
set :log_level, :info

# Default value for :pty is false
# set :pty, true

# Default value for :linked_files is []
# set :linked_files, %w{config/database.yml}

# Default value for linked_dirs is []
# set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
set :keep_releases, 5

# role :web, "your web-server here"                          # Your HTTP server, Apache/etc
# role :app, "your app-server here"                          # This may be the same as your `Web` server
# role :db,  "your primary db-server here", :primary => true # This is where Rails migrations will run
# role :db,  "your slave db-server here"

set :assets_roles, [:web, :app]

namespace :deploy do

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute :touch, release_path.join("tmp/restart.txt")
    end
  end

  after :publishing, :restart

  # after :restart, :clear_cache do
  #   on roles(:web), in: :groups, limit: 3, wait: 10 do
  #     # Here we can do anything such as:
  #     # within release_path do
  #     #   execute :rake, 'cache:clear'
  #     # end
  #   end
  # end

  task :start do ; end
  task :stop do ; end

  task :prepare_broker do
    on roles(:app) do
      execute "test -f #{fetch(:shared_path)}/cdp.config || cp #{fetch(:release_path)}/broker/cdp.config #{fetch(:shared_path)}"
      execute "ln -nfs #{fetch(:shared_path)}/cdp.config #{fetch(:release_path)}/broker/cdp.config"

      execute "test -d #{fetch(:shared_path)}/log/broker || mkdir #{fetch(:shared_path)}/log/broker"
      execute "ln -nfs #{fetch(:shared_path)}/log/broker #{fetch(:release_path)}/broker/log"
    end
  end

  task :compile_broker do
    on roles(:app) do
      execute "make -C #{fetch(:release_path)}/broker"
    end
  end

  task :symlink_configs do
    on roles(:app) do
      %W(credentials cdp newrelic oauth nuntium poirot).each do |file|
        execute "ln -nfs #{fetch(:shared_path)}/#{file}.yml #{fetch(:release_path)}/config/"
      end
    end
  end

  task :symlink_data do
    on roles(:app) do
      execute "ln -nfs #{fetch(:shared_path)}/data #{fetch(:release_path)}/"
    end
  end

  task :generate_version do
    on roles(:app) do
      execute "cd #{fetch(:current_path)} && git describe --always > #{fetch(:release_path)}/VERSION"
    end
  end
end

namespace :foreman do
  desc 'Export the Procfile to Ubuntu upstart scripts'
  task :export do
    on roles(:app) do
      execute "echo -e \"PATH=$PATH\\nGEM_HOME=$GEM_HOME\\nGEM_PATH=$GEM_PATH\\nRAILS_ENV=production\" >  #{fetch(:current_path)}/.env"
      execute "cd #{fetch(:current_path)} && rvmsudo bundle exec foreman export upstart /etc/init -f #{fetch(:current_path)}/Procfile -a #{fetch(:application)} -u #{fetch(:user)} --concurrency=\"broker=1,delayed=1\""
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
end

# before "deploy:start", "deploy:migrate"
# before "deploy:restart", "deploy:migrate"
# after 'deploy:publishing', 'deploy:restart'
# after "deploy:publishing", "foreman:export"    # Export foreman scripts
# after "deploy:restart", "foreman:restart"   # Restart application scripts

# after "deploy:update_code", "deploy:generate_version"
# after "deploy:update_code", "deploy:symlink_configs"
# after "deploy:update_code", "deploy:symlink_data"
# after "deploy:update_code", "deploy:prepare_broker"
# after "deploy:update_code", "deploy:compile_broker"
