Rails.application.routes.draw do
  resources :todos do
    member do
      put :dependencies, to: 'todos#update_dependencies'
    end
  end
  resources :projects
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  # root "articles#index"
end
