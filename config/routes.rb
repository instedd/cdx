Rails.application.routes.draw do
  devise_for :users, controllers: {omniauth_callbacks: "omniauth_callbacks"}
  guisso_for :user

  resources :laboratories
  resources :institutions do
    member do
      get :request_api_token
    end
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
  end

  resources :locations, only: [:index, :show]
  resources :manifests, except: [:update, :destroy]
  resources :test_results
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
