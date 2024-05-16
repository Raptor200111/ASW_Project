Rails.application.config.middleware.insert_before 0, Rack::Cors do
# config/initializers/cors.rb
  allow do
    origins '*'
    resource '*', headers: :any, methods: [:get, :post, :patch, :put, :delete]
  end
end