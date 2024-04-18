Rails.application.routes.draw do

  devise_for :users, controllers: {
    registrations: 'users/registrations',
    sessions: 'users/sessions',
    omniauth_callbacks: 'users/omniauth_callbacks'
  }
  get '/u/:id', to: 'users#profile', as: 'user'

  resources :articles do
    member do
      post 'vote_up'
      post 'vote_down'
      put 'boost'
    end
    get 'new_link', on: :collection
    get 'search', on: :collection
    resources :comments do
      member do
        post 'vote_up'
        post 'vote_down'
      end
    end
  end
  resources :magazines
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  root 'articles#index'
  #root 'magazines#index'
end
