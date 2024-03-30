Rails.application.routes.draw do

  root 'articles#index'
  devise_for :users, controllers: {
    registrations: 'users/registrations',
    sessions: 'users/sessions',
    omniauth_callbacks: 'users/omniauth_callbacks'
  }
  resources :articles
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
end
