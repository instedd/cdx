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
        get 'regenerate_key'
      end
    end
  end

  resources :locations
  resources :manifests, except: [:update]
  resources :events
  resources :subscribers
  resources :policies

  root :to => 'home#index'

  namespace :api, defaults: { format: 'json' } do
    resources :playground, only: :index, defaults: { format: 'html' }
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
      resources :events, only: :create, shallow: true
    end
    resources :laboratories, only: :index
  end
end
