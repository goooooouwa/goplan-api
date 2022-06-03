require 'sidekiq/web'

Rails.application.routes.draw do
  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }
  devise_scope :user do
    delete 'sign_out', :to => 'devise/sessions#destroy'
  end
  resources :todos do
    member do
      put :dependencies, to: 'todos#update_dependencies'
    end
  end
  resources :projects

  mount Sidekiq::Web => "/sidekiq" # mount Sidekiq::Web in your Rails app

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root to: "projects#index"
end
