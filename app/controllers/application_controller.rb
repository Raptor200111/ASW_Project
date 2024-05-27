class ApplicationController < ActionController::Base
  # skip_before_action :verify_authenticity_token

  # Removed the set_cors_headers method and before_action

  def hello
    render html: "<h1>It works WASLAB04!</h1>".html_safe
  end
end
