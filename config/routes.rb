Rails.application.routes.draw do
  get 'vote_articles/index'
  get 'vote_articles/show'
  get 'vote_articles/new'
  get 'vote_articles/edit'

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
      post 'boost'
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
  resources :magazines do
    member do
      put 'subscribe'
    end
  end

  resources :vote_articles
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  root 'articles#index'
  #root 'magazines#index'
end
