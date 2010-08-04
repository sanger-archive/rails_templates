class SessionsController < ApplicationController
  skip_before_filter :login_required
  filter_parameter_logging :password

  def index
    render(:action => 'login')
  end

  def login
    self.current_user = authenticate(params[:login], params[:password])
    if logged_in?
      flash[:notice] = t('controllers.sessions.messages.logged_in')
      redirect_back_or_default(root_url)
    else
      flash[:error] = t('controllers.sessions.messages.invalid_details')
      redirect_to(login_path)
    end
  end

  def logout
    self.current_user.forget_me if logged_in?
    cookies.delete :WTSISignOn
    flash[:notice] = t('controllers.sessions.messages.logged_out')
    redirect_back_or_default(root_url)
  end

private
  
  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
  ensure
    session[:return_to] = nil
  end

end
