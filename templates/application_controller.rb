# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  attr_accessor :current_user

#  include ExceptionNotification::Notifier
  include SangerAuthentication
  before_filter :login_required
  filter_parameter_logging :password, :credential_1, :uploaded_data
  
  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password
end
