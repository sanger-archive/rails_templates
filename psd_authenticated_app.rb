# This enables us to load some files from the remote repository, just like we were using 'load'
eval(open(File.join(File.dirname(template), 'template_helpers.rb')).read)

git_commit('Initial project setup') do
  # Set up RVM
  rvm_create_gemset(application_name)
  rvm_create_rc(application_name)

  # Setup Bundler
  bundler_install do
    source 'http://rubygems.org'

    gem 'rails', '~>2.3'
    gem 'mysql'
    gem 'configatron'
    gem 'curb'
    gem 'will_paginate', '>2.2.3'
    gem 'exception_notifier'
    gem 'acts_as_audited'
    gem 'sqlite3-ruby', '~>1.2.5'

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
  git_ignore('log/*.log', 'db/*/sqlite3', 'rerun.txt', 'tmp')
  git_ignore_directories('log', 'tmp', 'vendor')

  # Setup Cucumber
  log('cucumber', 'Setting up cucumber ...')
  generate('cucumber')

  # Remove some unused files
  remove_unused_files('public/index.html', 'README')

  initializer 'exception_notifier.rb'
  initializer 'load_config.rb'
  initializer 'release.rb'

  # Setup the authentication
  authentication_install

  # TODO: style
  # TODO: Role controller

  file 'db/seeds.rb'
  mkdir 'db/seeds'

  file 'config/config.yml'

  file 'app/controllers/application_controller.rb'
  file 'app/helpers/application_helper.rb'
  file 'app/views/layouts/application.html.erb'

  file 'public/stylesheets/screen.css'

  file 'public/images/sequencescape.gif'
  file 'public/images/scape-large-dark.jpg'

  # rake "db:migrate"

  puts "Define a map.root in your config/route.rb"
  puts "Remember to remove view/layouts/<model>.html.erb when scaffolding"
end
