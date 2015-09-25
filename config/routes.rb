require 'sidekiq/web'

Rails.application.routes.draw do
  mount Sidekiq::Web => '/sidekiq' if Rails.env == 'development'

  devise_for :users, controllers: {
    omniauth_callbacks: "omniauth_callbacks",
    sessions: "sessions",
  }

  resources :laboratories
  resources :institutions, except: :show do
    member do
      get :request_api_token
    end
  end

  resources :encounters, only: [:new, :create, :edit] do
    member do
      put 'samples/:sample_id' => 'encounters#add_sample'
    end
    collection do
      get :search_sample
      get :search_test
    end
  end
  resources :locations, only: [:index, :show]
  resources :devices do
    member do
      get  'regenerate_key'
      post 'generate_activation_token'
    end
    resources :custom_mappings, only: [:index]
    resources :ssh_keys, only: [:create, :destroy]
    resources :device_messages, only: [:index], path: 'messages' do
      member do
        get 'raw'
        post 'reprocess'
      end
    end
  end
  resources :device_models
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
    resources :laboratories, only: :index
  end

  scope :api, format: 'json', except: [:new, :edit] do
    resources :filters do
      resources :subscribers
    end
    resources :subscribers
  end
end
