Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: 'users/registrations',
    sessions: 'users/sessions',
    omniauth_callbacks: 'users/omniauth_callbacks'
  }
  devise_scope :user do
    get '/u/:id', to: 'users#profile', as: 'user'
    get 'u/:id/articles', to: 'users#show_articles'
    get 'u/:id/comments', to: 'users#show_comments'
    get 'u/:id/boosts', to: 'users#show_boosts'
    patch '/u/:id', to: 'users#update'
    patch '/u/:id/deleteAvatar', to: 'users#deleteAvatar'
    patch '/u/:id/deleteBack', to: 'users#deleteBack'
  end

  #put '/u/:id', to: 'users/sessions', as: 'user'

  resources :articles do
    member do
      post 'vote_up'
      post 'vote_down'
      post 'vote'
      post 'boost_web'
      post 'boost'
      delete 'unboost'
      delete 'unvote_up'
      delete 'unvote_down'
    end
    get 'new_link', on: :collection
    get 'search', on: :collection
    resources :comments do
      member do
        post :vote_up
        delete :remove_vote_up
        post :vote_down
        delete :remove_vote_down
      end
    end
  end

  resources :magazines do
    member do
      post 'subscribe'
      get 'articles'
      delete 'unsubscribe'
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  get 'commentOrder', to: 'articles#commentOrder'

  root 'articles#index'
  #root 'magazines#index'
end
