# bort.rb

#plugin 'exception_notifier', 
#  :git => 'http://github.com/rails/exception_notification.git', :revision => "2-3-stable"
plugin 'rails-authorization-plugin',
  :git => 'git://github.com/DocSavage/rails-authorization-plugin.git'
plugin 'acts_as_audited',
  :git => 'git://github.com/collectiveidea/acts_as_audited.git'
plugin 'sanger_authentication',
  :git => 'ssh://git.internal.sanger.ac.uk/repos/git/psd/sanger_authentication.git'
 
gem 'mislav-will_paginate', :version => '~> 2.2.3', 
  :lib => 'will_paginate',  :source => 'http://gems.github.com'
gem 'markbates-configatron', :lib => 'configatron',
   :source => 'http://gems.github.com'
gem 'curb'

rake "gems:install"
rake "gems:unpack"
rake "gems:build"
#gem 'rubyist-aasm', :version => '2.1.1', 
#  :lib => 'rubyist-aasm', :source => 'http://gems.github.com'

route 'map.login "/login", :controller => "sessions", :action => "login"'
route 'map.logout "/logout", :controller => "sessions", :action => "logout"'
 
generate("audited_migration", "add_audits_table")
generate("role_model", "role")
generate(:model, "User", "login:string", "cached_cookie:string")

# TODO: style
# TODO: Role controller
app_name = "tesT"#ask('Name of application')
deploy_name = "test_app"#ask('Deploy name')

# Remove default HTML page
run("rm public/index.html")


def get_file(file_name)
#  template = File.expand_path(File.dirname(__FILE__) + "/templates/#{file_name}")
  template = File.expand_path("/Users/lj3/Projects/sequencescape/rails_templates/templates/#{file_name}")
  File.read(template)
end

file 'config/config.yml', get_file("config.yml")
initializer 'exception_notifier.rb',  get_file("exception_notifier.rb")
initializer 'load_config.rb',  get_file("load_config.rb")
initializer 'release.rb',  get_file("release.rb")

file 'app/helpers/application_helper.rb', get_file("application_helper.rb")
file 'app/models/user.rb', get_file("user.rb")
file 'app/controllers/application_controller.rb', get_file("application_controller.rb")
file 'app/views/layouts/application.html.erb', get_file("application.html.erb")
file 'app/views/layouts/sessions.html.erb', get_file("sessions.html.erb")
file 'app/controllers/sessions_controller.rb', get_file("sessions_controller.rb")
file 'app/views/sessions/login.html.erb', get_file("login.html.erb")

rake "db:migrate"
