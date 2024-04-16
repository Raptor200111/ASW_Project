Rails.application.routes.draw do
  resources :articles do
    member do
      put 'vote_up'
      put 'vote_down'
    end
    get 'new_link', on: :collection
    get 'search', on: :collection
    resources :comments
  end
  resources :magazines
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  root 'articles#index'
  root 'magazines#index'
end
