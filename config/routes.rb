Rails.application.routes.draw do
  resources :articles do
    resources :comments
  end
  resources :magazines
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  root 'magazines#index'

end
