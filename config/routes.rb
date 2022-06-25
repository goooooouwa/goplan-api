require 'sidekiq/web'

Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  use_doorkeeper
  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks'
  }

  resources :todos do
    member do
      put 'dependencies', to: 'todos#update_dependencies'
    end
  end
  resources :projects
  get 'profile', to: 'users#show'
  get 'me', to: 'account#show'
  put 'me', to: 'account#update'

  mount Sidekiq::Web => "/sidekiq" # mount Sidekiq::Web in your Rails app

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root to: "home#index"
  root to: redirect(ENV['GOPLAN_WEB_BASE_URL'])
end
