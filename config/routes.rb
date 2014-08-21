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
  scope '/api' do
    get 'playground' => 'api#playground'
    match 'events(.:format)' => 'api#events', via: [:get, :post], defaults: { format: 'json' }
    get 'events/:event_uuid/custom_fields' => 'api#custom_fields'
    get 'events/:event_uuid/pii' => 'api#pii'
    post '/devices/:device_uuid/events' => 'api#create'
  end
end
