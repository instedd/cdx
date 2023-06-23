require 'sidekiq/web'
require 'sidekiq/cron/web'

Rails.application.routes.draw do
  use_doorkeeper
  mount Sidekiq::Web => '/sidekiq' if Rails.env == 'development'

  concern :editable_user_registration do
    as :user do
      get 'users/registration/edit', to: 'registrations#edit', as: :edit_user_registration, defaults: { format: 'html' }
      match 'users/registration/update(.:model)', to: 'registrations#update', as: :registration, via: [:post, :put]
    end
  end

  if Settings.single_tenant
    devise_for(
      :users,
      controllers: {
        sessions: 'sessions',
        invitations: 'users/invitations'
      }
    )
    concerns :editable_user_registration
  elsif Settings.public_registration
    devise_for(
      :users,
      controllers: {
        omniauth_callbacks: 'omniauth_callbacks',
        sessions: 'sessions',
        registrations: 'registrations',
        invitations: 'users/invitations'
      },
      path_names: {
        registration: 'registration'
      }
    )
  else
    devise_for(
      :users,
      controllers: {
        omniauth_callbacks: 'omniauth_callbacks',
        sessions: 'sessions',
        invitations: 'users/invitations'
      }
    )
    concerns :editable_user_registration
  end

  get 'settings' => 'home#settings'
  get 'samples/upload_results'

  resources :sites, except: [:show] do
    member do
      get :devices
      get :tests
    end
  end

  resources :institutions, except: :show do
    collection do
      get :pending_approval
      get :no_data_allowed
      get :new_from_invite_data
    end
  end

  resources :encounters, only: [:new, :create, :edit, :update, :show] do
    collection do
      get :new_index

      get :sites
      get :search_sample
      get :search_test
      put 'add/sample/:sample_uuid' => 'encounters#add_sample'
      put 'add/new_sample' => 'encounters#new_sample'
      put 'add/manual_sample_entry' => 'encounters#add_sample_manually'
      put 'add/test/:test_uuid' => 'encounters#add_test'
      put 'merge/sample/' => 'encounters#merge_samples'
    end
  end
  resources :locations, only: [:index, :show]
  resources :devices do
    member do
      get  :regenerate_key
      get :generate_activation_token
      post :request_client_logs
      get :performance
      get :tests
      get :logs
      get :setup
      post :send_setup_email
    end
    collection do
      post 'custom_mappings'
    end
    resources :custom_mappings, only: [:index]
    resources :ssh_keys, only: [:create, :destroy]
    resources :device_logs, only: [:index, :show, :create]
    resources :device_commands, only: [:index] do
      member do
        post 'reply'
      end
    end
  end
  resources :device_models do
    member do
      put 'publish'
      get 'manifest'
    end
  end

  resources :device_messages, only: [:index], path: 'messages' do
    member do
      get 'raw'
      post 'reprocess'
    end
  end
  resources :samples do
    member do
      get 'print'
      get 'edit_or_show'
    end
    collection do
      get 'autocomplete'
      get 'existing_uuids'
      post 'bulk_action', constraints: lambda { |request| request.params[:bulk_action] == 'process_csv' }, action: :bulk_process_csv
      post 'bulk_action', constraints: lambda { |request| request.params[:bulk_action] == 'print' }, action: :bulk_print
      post 'bulk_action', constraints: lambda { |request| request.params[:bulk_action] == 'destroy' }, action: :bulk_destroy
    end
  end
  resources :samples_reports do
    member do
      get 'show'
      delete 'delete'
      get 'nih_tables', to: 'nih_tables#show'
    end
    collection do
      get 'update_threshold'
      get "find_box"
      get 'autocomplete'
      post 'bulk_action', constraints: lambda { |request| request.params[:bulk_action] == 'destroy' }, action: :bulk_destroy
    end
  end
  resources :transfer_packages, only: [:new, :create, :index, :show] do
    member do
      post :unblind
      patch 'confirm'
    end
    collection do
      get "find_box"
    end
  end
  resources :batches do
    member do
      get 'edit_or_show'
      post 'add_sample'
    end
    collection do
      get 'autocomplete'
      get 'existing_batch_number'
      post 'bulk_action', constraints: lambda { |request| request.params[:bulk_action] == 'destroy' }, action: :bulk_destroy
    end
  end
  resources :boxes, except: [:edit, :update] do
    member do
      post :unblind
      post :blind
      get 'print'
      get 'inventory', constraints: { format: 'csv' }
    end
    collection do
      post 'bulk_action', constraints: lambda { |request| request.params[:bulk_action] == 'destroy' }, action: :bulk_destroy
    end
  end

  post '/csv_validation/:context', to: 'csv_validations#create', as: 'csv_validation'

  resources :qc_infos
  resources :test_results , only: [:index, :show]
  resources :filters, format: 'html'
  resources :subscribers
  resources :policies
  resources :api_tokens
  resources :patients do
    collection do
      get :search
    end
  end

  get 'loinc_codes/search' => 'loinc_codes#search'
  post 'assay_files/create' => 'assay_files#create'


  resources :alerts, except: [:show]
  resources :incidents, only: [:index]
  resources :alert_messages, only: [:index]

  scope :dashboards, controller: :dashboards do
    get :index, as: :dashboard
    get :nndd
  end

  devise_scope :user do
    root to: "devise/sessions#new"
  end
  get 'verify' => 'home#verify'
  if Rails.env.development?
    get 'join' => 'home#join'
    get 'design' => 'home#design'
  end

  namespace :api, defaults: { format: 'json' } do
    resources :activations, only: :create
    resources :playground, only: :index, defaults: { format: 'html' } do
      collection do
        get :simulator
      end
    end
    match 'tests(.:format)' => "tests#index", via: [:get, :post]
    resources :tests, only: [] do
      collection do
        get :schema
      end
      member do
        get :pii
      end
    end
    match 'encounters(.:format)' => "encounters#index", via: [:get, :post]
    resources :encounters, only: [] do
      collection do
        get :schema
      end
      member do
        get :pii
      end
    end
    resources :devices, only: [] do
      resources :messages, only: [:create ], shallow: true
      match 'tests' => "messages#create", via: :post # For backwards compatibility with Qiagen-Esequant-LR3
      match 'demodata' => "messages#create_demo", via: :post
    end
    resources :sites, only: :index
    resources :institutions, only: :index
    resources :filters, only: [:index, :show] do
      resources :subscribers
    end
    resources :subscribers
  end

  resources :users, except: [:new] do
    member do
      post :assign_role
      post :unassign_role
    end
    collection do
      get :autocomplete
      post :update_setting
      get :no_data_allowed
      post :create_with_institution_invite
    end
  end
  resources :roles do
    collection do
      get :autocomplete
      get :search_device
    end
  end

  get 'nndd' => 'application#nndd' if Rails.env.test?

  if Rails.env.test?
    get "/tests/user_token_authentication", to: "tests#user_token_authentication"
  end
end
