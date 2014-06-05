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
set :linked_files, %w{config/database.yml config/settings.yml config/guisso.yml}

# Default value for linked_dirs is []
# set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}
set :linked_dirs, %w{log}

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

  before :restart, :migrate
  after :publishing, :restart

  # after :publishing, :prepare_backend

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

  # task :prepare_backend do
  #   on roles(:app) do
  #     execute "test -f #{fetch(:shared_path)}/cdp.config || cp #{release_path}/backend/cdp.config #{fetch(:shared_path)}"
  #     execute "ln -nfs #{fetch(:shared_path)}/cdp.config #{release_path}/backend/cdp.config"

  #     execute "test -d #{fetch(:shared_path)}/log/backend || mkdir #{fetch(:shared_path)}/log/backend"
  #     execute "ln -nfs #{fetch(:shared_path)}/log/backend #{release_path}/backend/log"
  #   end
  # end

  task :compile_backend do
    on roles(:app) do
      within "#{release_path}/backend" do
        with :mix_env => :prod do
          execute :mix, "do deps.get, compile > #{release_path}/backend/mix.output 2>&1"
        end
      end
    end
  end
  after :publishing, :compile_backend

  task :restart_backend do
    on roles(:app) do
      execute "sudo stop cdp || true >> foo.txt 2>&1"
      execute "sudo start cdp >> foo.txt 2>&1"
    end
  end
  after :compile_backend, :restart_backend

  task :generate_version do
    on roles(:app) do
      execute :echo, "#{fetch(:current_revision)} > #{release_path}/VERSION"
    end
  end
  after :publishing, :generate_version
end
