Rails.application.routes.draw do

  devise_for :users, controllers: {
    registrations: 'users/registrations',
    sessions: 'users/sessions',
    omniauth_callbacks: 'users/omniauth_callbacks'
  }
  resources :articles do
    member do
      put 'vote_up'
      put 'vote_down'
      put 'toggle_boosted'
    end
    get 'new_link', on: :collection
    get 'search', on: :collection
    resources :comments do
      member do
        put 'vote_up'
        put 'vote_down'
      end
    end
  end
  resources :magazines
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  root 'articles#index'
  #root 'magazines#index'
end
