Rails.application.routes.draw do
  
  resources :articles do
    resources :comments
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  root 'articles#index'
end
