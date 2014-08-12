# config valid only for Capistrano 3.1
lock '3.1.0'

set :application, "cdp"
set :repo_url,  "git@bitbucket.org:instedd/cdp.git"

set :rvm_ruby_version, '2.0.0-p353'
set :rvm_type, :system
set :rails_env, 'production'
set :deploy_via, :remote_cache
set :user, 'ubuntu'

set :default_env, { 'TERM' => ENV['TERM'] }

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }

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

namespace :deploy do

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      execute :touch, release_path.join("tmp/restart.txt")
    end
  end

  # before :restart, :migrate
  after :publishing, :restart

  task :start do ; end
  task :stop do ; end

  task :generate_version do
    on roles(:app) do
      execute :echo, "#{fetch(:current_revision)} > #{release_path}/VERSION"
    end
  end
  after :publishing, :generate_version

  namespace :foreman do
    desc 'Export the Procfile to Ubuntu upstart scripts'

    task :export do
      on roles(:app) do
        execute :echo, "-e \"PATH=$PATH\\nGEM_HOME=$GEM_HOME\\nGEM_PATH=$GEM_PATH\\nRAILS_ENV=production\" >  #{release_path}/.env"
        # within current_path do
        #   execute "#{fetch(:rvm_path)}/bin/rvmsudo #{fetch(:rvm_path)}/bin/bundle exec foreman export upstart /etc/init -f #{current_path}/Procfile -a #{fetch(:application)} -u #{fetch(:user)} --concurrency=\"subscribers=1\""
        # end

        # on roles(:app) do
          execute [
            "cd #{release_path} &&",
            'export rvmsudo_secure_path=0 && ',
            "#{fetch(:rvm_path)}/bin/rvm #{fetch(:rvm_ruby_version)} do",
            'rvmsudo',
            "#{fetch(:rvm_path)}/bin/bundle exec foreman export -a #{fetch(:application)} -u #{fetch(:user)} upstart /etc/init --concurrency=\"subscribers=1\""
            # "bundle exec foreman export -a #{fetch(:application)} -u #{fetch(:user)} -p 8787 upstart /etc/init"
          ].join(' ')
        # end
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

  # after "deploy:updated", "foreman:export"    # Export foreman scripts
  after :restart, "foreman:restart"   # Restart application scripts
end
