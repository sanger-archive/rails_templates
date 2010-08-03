# This enables us to load some files from the remote repository, just like we were using 'load'
eval(open(File.join(File.dirname(template), 'template_helpers.rb')).read)

git_commit('Initial project setup') do
  # Set up RVM
  rvm_create_gemset(application_name)
  rvm_create_rc(application_name)

  # Setup Bundler
  bundler_install_into_rails
  bundle do
    source 'http://rubygems.org'

    gem 'rails', '~>2.3'
    gem 'mysql'
    gem 'configatron'
    gem 'curb'
    gem 'will_paginate', '>2.2.3'
    gem 'exception_notifier'
    gem 'acts_as_audited'
    gem 'sqlite3-ruby', '~>1.2.5'
    gem 'formtastic', '~>0.9.10'

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
  end

  # Setup some git ignores
  git_ignore('log/*.log', 'db/*.sqlite3', 'rerun.txt', 'tmp')
  git_ignore_directories('log', 'tmp', 'vendor')

  # Setup Cucumber
  log('cucumber', 'Setting up cucumber ...')
  generate('cucumber')

  # Remove some unused files
  remove_unused_files('public/index.html', 'README')

  initializer  'exception_notifier.rb'
  initializer  'load_config.rb'
  erb_template 'config/initializers/release.rb'

  # Standard application setup ...
  file  'db/seeds.rb'
  mkdir 'db/seeds'
  file  'config/config.yml'
  file  'public/images/application.gif'
  file  'public/images/application-large-dark.jpg'

  file 'app/helpers/application_helper.rb'
  file 'app/views/layouts/application.html.erb'

  # Setup compass/sass stylesheets ...
  compass_install
  compass_stylesheets('_flash-messages', 'screen', 'application')
  compass_plugin('yui', 'http://github.com/chriseppstein/yui-compass-plugin.git')

  # Setup the authentication
  authentication_install

  # Temporary site controller for all applications
  generate('controller', 'site index')
  route('map.root :controller => "site"')
end
