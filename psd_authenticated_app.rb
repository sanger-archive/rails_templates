def run_in_gemset(command)
  run "bash -l -c 'rvm gemset use #{APP_NAME} && #{command}'"
end

def get_file(file_name)
  open(File.join(File.dirname(template), 'templates', file_name)).read
end

# Set up Git in our shiny new Sanger application
git :init

APP_NAME = Dir.pwd.split('/').last 

# Setup Bundler
file 'Gemfile', %{
source 'http://rubygems.org'

gem 'rails', '~>2.3'
gem 'mysql'
gem 'configatron'
gem 'curb'
gem 'will_paginate', '>2.2.3'
gem 'exception_notifier'
gem 'acts_as_audited'
gem 'sqlite3-ruby'

group :development do
  gem 'ruby-debug'
  gem 'mongrel'
  gem 'sinatra'
end

group :test do
  gem 'shoulda'
  # Factory Girl is frozen at 1.2.4 for Rails 2.3.x
  gem 'factory_girl', '1.2.4'
  gem 'redgreen'
end

group :cucumber do
  gem 'cucumber-rails'
  gem 'database_cleaner'
  gem 'webrat'
end
}.strip

file 'config/preinitializer.rb', %{
begin
  require "rubygems"
  require "bundler"
rescue LoadError
  raise "Could not load the bundler gem. Install it with `gem install bundler`."
end

if Gem::Version.new(Bundler::VERSION) <= Gem::Version.new("0.9.24")
  raise RuntimeError, "Your bundler version is too old." +
   "Run `gem install bundler` to upgrade."
end

begin
  # Set up load paths for all bundled gems
  ENV["BUNDLE_GEMFILE"] = File.expand_path("../../Gemfile", __FILE__)
  Bundler.setup
rescue Bundler::GemNotFound
  raise RuntimeError, "Bundler couldn't find some gems." +
    "Did you run `bundle install`?"
end

}.strip

gsub_file 'config/boot.rb', "Rails.boot!", %{

class Rails::Boot
  def run
    load_initializer

    Rails::Initializer.class_eval do
      def load_gems
        @bundler_loaded ||= Bundler.require :default, Rails.env
      end
    end

    Rails::Initializer.run(:set_load_path)
  end
end


Rails.boot!

}.strip

# Set up RVM
run "rvm gemset create #{APP_NAME}"

puts "Creating .rvmrc..."

file '.rvmrc', %{
rvm use #{ENV['RUBY_VERSION'].sub(/-p\d+$/, "")}
rvm gemset use #{APP_NAME}
}.strip

puts "Installing default Gems..."
# To get GEM_HOME set correctly we need to explicitly change gemsets and call
# Bundler from the same Bash login shell...
# run "bash -l -c 'rvm gemset use #{APP_NAME} && bundle install'"
run_in_gemset "bundle install"


append_file '.gitignore', %{
.bundler
log/*.log
db/*.sqlite3
rerun.txt
tmp
}

# Add empty .gitignore files so that git stores directory structure.
run 'touch log/.gitignore tmp/.gitignore vendor/.gitignore'


# plugin 'rails-authorization-plugin',
#   :git => 'http://github.com/DocSavage/rails-authorization-plugin.git'

# To get GEM_HOME set correctly we need to explicitly change gemsets
# run "bash -l -c 'rvm gemset use #{APP_NAME} && ./script/plugin install http://github.com/DocSavage/rails-authorization-plugin.git'"

# plugin 'sanger_authentication',
#   :git => 'ssh://git.internal.sanger.ac.uk/repos/git/psd/sanger_authentication.git'

# run "bash -l -c 'rvm gemset use #{APP_NAME} && ./script/plugin install ssh://git.internal.sanger.ac.uk/repos/git/psd/sanger_authentication.git'"

run_in_gemset "./script/plugin install http://github.com/DocSavage/rails-authorization-plugin.git"


run_in_gemset "./script/plugin install ssh://git.internal.sanger.ac.uk/repos/git/psd/sanger_authentication.git"

puts "Setting up Cucumber..."
run_in_gemset "./script/generate cucumber"

puts "Setting up default routes..."
route 'map.login "/login", :controller => "sessions", :action => "login"'
route 'map.logout "/logout", :controller => "sessions", :action => "logout"'
 
# generate("audited_migration", "add_audits_table")
run_in_gemset "./script/generate audited_migration add_audits_table"

# generate("role_model", "role")
run_in_gemset "./script/generate role_model role"

# generate(:model, "User", "login:string", "cached_cookie:string")
run_in_gemset "./script/generate User login:string cached_cookie:string"


# TODO: style
# TODO: Role controller

puts "Removing unused default files..."
# Remove default HTML page
run("rm public/index.html")

# Remove the default README
run("rm README")


file 'config/config.yml', get_file("config.yml")

initializer 'exception_notifier.rb',  get_file("exception_notifier.rb")
initializer 'load_config.rb',  get_file("load_config.rb")
initializer 'release.rb',  get_file("release.rb")

file 'app/helpers/application_helper.rb', get_file("application_helper.rb")
file 'app/models/user.rb', get_file("user.rb")
file 'app/controllers/application_controller.rb', get_file("application_controller.rb")

file 'public/stylesheets/screen.css', get_file("screen.css")
file 'public/stylesheets/sessions.css', get_file("sessions.css")


file 'app/views/layouts/application.html.erb', get_file("application.html.erb")
file 'app/views/layouts/sessions.html.erb', get_file("sessions.html.erb")
file 'app/controllers/sessions_controller.rb', get_file("sessions_controller.rb")
file 'app/views/sessions/login.html.erb', get_file("login.html.erb")

file 'public/images/sequencescape.gif', get_file("sequencescape.gif")
file 'public/images/scape-large-dark.jpg', get_file("scape-large-dark.jpg")

# rake "db:migrate"

puts "Define a map.root in your config/route.rb"
puts "Remember to remove view/layouts/<model>.html.erb when scaffolding"

git :add => ".", :commit => "-m Initial Commit"  
