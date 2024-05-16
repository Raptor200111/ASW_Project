class ApplicationController < ActionController::Base
  #skip_before_action :verify_authenticity_token
  before_action :set_cors_headers

  def set_cors_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS'
    headers['Access-Control-Allow-Headers'] = 'Origin, Content-Type, Accept, Authorization'
  end

  def hello
    render html: "<h1>It works WASLAB04!</h1>".html_safe
  end
end
