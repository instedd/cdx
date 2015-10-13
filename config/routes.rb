require 'sidekiq/web'

Rails.application.routes.draw do
  mount Sidekiq::Web => '/sidekiq' if Rails.env == 'development'

  devise_for :users, controllers: {
    omniauth_callbacks: "omniauth_callbacks",
    sessions: "sessions",
  }

  resources :sites do
    member do
      get :devices
      get :tests
    end
  end

  resources :prospects do
    member do
      put :approve
    end
  end
  get '/user/request_access' => 'prospects#new'

  resources :laboratories
  resources :institutions, except: :show do
    member do
      get :request_api_token
    end
  end

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
  end

  scope :api, format: 'json', except: [:new, :edit] do
    resources :filters do
      resources :subscribers
    end
    resources :subscribers
  end

  scope :user do
    get 'settings' => "users#settings"
    patch 'settings' => "users#update_settings"
  end
end
