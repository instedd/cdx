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
    resources :subscribers
  end

  resources :locations
  resources :manifests
  resources :users

  root :to => 'home#index'
end
