Cdp::Application.routes.draw do
  devise_for :users, controllers: {omniauth_callbacks: "omniauth_callbacks"}
  guisso_for :user

  resources :institutions do
    member do
      get :request_api_token
    end
    resources :laboratories
    resources :devices do
      member do
        get  'regenerate_key'
        post 'generate_activation_token'
      end
      resources :ssh_keys, only: [:create, :destroy]
    end
  end

  resources :locations
  resources :manifests, except: [:update]
  resources :events
  resources :filters
  resources :subscribers
  resources :policies

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
      resources :events, only: [:create], shallow: true do
        collection do
          post :upload
        end
      end
    end
    resources :laboratories, only: :index
    resources :filters
  end
end
