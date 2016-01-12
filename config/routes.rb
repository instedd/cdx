require 'sidekiq/web'
require 'sidekiq/cron/web'

Rails.application.routes.draw do
  use_doorkeeper
  mount Sidekiq::Web => '/sidekiq' if Rails.env == 'development'

  devise_for :users,
    controllers: {
      omniauth_callbacks: 'omniauth_callbacks',
      sessions: 'sessions',
      registrations: 'registrations',
      invitations: 'users/invitations'
    },
    path_names: {
      registration: 'registration'
    }

  resources :sites do
    member do
      get :devices
      get :tests
      get :dependencies
    end
  end

  resources :institutions, except: :show do
    collection do
      get :pending_approval
    end
  end

  resources :encounters, only: [:new, :create, :edit, :update, :show] do
    collection do
      get :sites
      get :search_sample
      get :search_test
      put 'add/sample/:sample_uuid' => 'encounters#add_sample'
      put 'add/new_sample' => 'encounters#new_sample'
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
    resources :device_messages, only: [:index], path: 'messages' do
      member do
        get 'raw'
        post 'reprocess'
      end
    end
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
  resources :test_results , only: [:index, :show]
  resources :filters, format: 'html'
  resources :subscribers
  resources :policies
  resources :api_tokens

  scope :dashboards, controller: :dashboards do
    get :nndd
  end

  devise_scope :user do
    root to: "devise/sessions#new"
  end
  get 'verify' => 'home#verify'
  get 'join' => 'home#join'
  get 'design' => 'home#design'

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
  end
  resources :roles do
    collection do
      get :autocomplete
    end
  end

  get 'nndd' => 'application#nndd' if Rails.env.test?
end
