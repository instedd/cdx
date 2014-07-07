Cdp::Application.routes.draw do
  devise_for :users, controllers: {omniauth_callbacks: "omniauth_callbacks"}
  guisso_for :user

  resources :institutions do
    resources :laboratories
    resources :devices do
      member do
        get 'regenerate_key'
      end
    end
  end

  resources :locations
  resources :manifests
  resources :events
  resources :subscribers
  resources :policies

  root :to => 'home#index'
  scope '/api' do
    get 'playground' => 'api#playground'
    match 'events' => 'api#events', via: [:get, :post]
    post '/devices/:device_uuid/events' => 'api#create'
  end
end
