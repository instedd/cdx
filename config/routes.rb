require 'sidekiq/web'

Rails.application.routes.draw do
  use_doorkeeper
  mount Sidekiq::Web => '/sidekiq' if Rails.env == 'development'

  devise_for :users, controllers: {
    omniauth_callbacks: "omniauth_callbacks",
    sessions: "sessions",
  }

  resources :sites do
    member do
      get :devices
      get :tests
      get :dependencies
    end
  end

  resources :institutions, except: :show

  resources :encounters, only: [:new, :create, :edit, :update, :show] do
    collection do
      get :institutions
      get :search_sample
      get :search_test
      put 'add/sample/:sample_uuid' => 'encounters#add_sample'
      put 'add/test/:test_uuid' => 'encounters#add_test'
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
    end
    collection do
      post 'custom_mappings'
      post 'new/device_models' => 'devices#device_models'
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
    end
  end
  resources :test_results , only: [:index, :show] do
    collection do
      get 'csv'
    end
  end
  resources :filters, format: 'html'
  resources :subscribers
  resources :policies
  resources :api_tokens

  scope :dashboards, controller: :dashboards do
    get :nndd
  end

  root :to => 'home#index'
  get 'verify' => 'home#verify'
  get 'confirm' => 'home#confirm'
  get 'join' => 'home#join'

  namespace :api, defaults: { format: 'json' } do
    resources :activations, only: :create
    resources :playground, only: :index, defaults: { format: 'html' } do
      collection do
        get :simulator
      end
    end
    match 'events(.:format)' => "events#index", via: [:get, :post]
    resources :events, only: [] do
      collection do
        get :schema
      end
      member do
        get :custom_fields
        get :pii
      end
    end
    resources :devices, only: [] do
      resources :messages, only: [:create], shallow: true
      match 'events' => "messages#create", via: :post # For backwards compatibility with Qiagen-Esequant-LR3
    end
    resources :sites, only: :index
    resources :institutions, only: :index
    resources :filters, only: [:index, :show] do
      resources :subscribers
    end
    resources :subscribers
  end

  scope :user do
    get 'settings' => "users#settings"
    patch 'settings' => "users#update_settings"
  end
end
