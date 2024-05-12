class ApplicationController < ActionController::Base
  skip_before_action :verify_authenticity_token
  def hello
    render html: "<h1>It works WASLAB04!</h1>".html_safe
  end
end
