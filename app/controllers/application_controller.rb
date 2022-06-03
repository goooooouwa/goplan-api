class ApplicationController < ActionController::API
  include ActionController::RequestForgeryProtection
  include ActionView::Layouts
  protect_from_forgery with: :exception, unless: -> { request.format.json? }
  before_action :authenticate_user!
end
