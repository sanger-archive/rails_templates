class User < ActiveRecord::Base
  include SangerUser
  
  acts_as_authorized_user
  acts_as_audited :protect => false

  def name
    self.login
  end

end
