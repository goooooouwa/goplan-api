class ApplicationController < ActionController::Base
  before_action :doorkeeper_authorize!
end
