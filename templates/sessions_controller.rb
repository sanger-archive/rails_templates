class SessionsController < ApplicationController
  
  skip_before_filter :login_required

  filter_parameter_logging :password

  def index
    redirect_to :action => :login
  end

  def login
    return unless request.post?
    self.current_user = authenticate(params[:username], params[:password])
    if logged_in?
      flash[:notice] = "Logged in successfully"
      redirect_back_or_default(root_url)
    else
      if params
        flash[:notice] = "Your log in details don't match our records. Please try again."
      end
    end
  end

  def logout
    self.current_user.forget_me if logged_in?
    cookie.delete :WTSISignOn
    flash[:notice] = "You have been logged out."
    redirect_back_or_default(root_url)
  end
  
  def redirect_back_or_default(default)
    session[:return_to] ? redirect_to(session[:return_to]) : redirect_to(default)
    session[:return_to] = nil
  end

end
