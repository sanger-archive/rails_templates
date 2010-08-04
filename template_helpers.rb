#####################################################################################################################
# This file contains helpers for dealing with Rails templates within the WTSI.  If you're writing a template then
# the first line of your template should be:
#
#   eval(open(File.join(File.dirname(template), 'template_helpers.rb')).read)
#
# Which will setup these helpers.
#####################################################################################################################

#####################################################################################################################
# Some helper methods that we need here but aren't available.
#####################################################################################################################
def alias_method_chain(method, extension)
  with, without = :"#{ method }_with_#{ extension }", :"#{ method }_without_#{ extension }"
  self.class_eval do
    alias_method(without, method)
    alias_method(method, with)
  end
end

# Left justifies the given string by determining the shortest whitespace sequence over all lines.  It assumes that
# the whitespace is made from space characters, so if you're using tabs then convert them first (you shouldn't be
# if you follow our coding standard)
def left_justify(string)
  shortest = ' ' * 100 # Arbitarily long string!
  string.dup.gsub(/^(\s+)[^\s]/m) { shortest = $1 if $1.length < shortest.length }
  string.gsub(/^#{ shortest }/m, '')
end

#####################################################################################################################
# Global helpers, used pretty much everywhere!
#####################################################################################################################
# Returns the name of the application being generated
def application_name
  File.basename(root)
end

# NOTE: Look out! Hack ahead! We're running in the context of a method call so we can't access the 'template' 
# variable inside another method.  So store it in a constant!
TEMPLATE = template
def get_file(file_name)
  open(File.join(File.dirname(TEMPLATE), 'templates', file_name)).read
end

def remove_unused_files(*files)
  log 'unused files', 'Removing unused files ...'
  run("rm #{ files.map(&:inspect).join(' ') }")
end

def initializer_with_templates(name, &block)
  content = get_file(File.join('config', 'initializers', name)) unless block_given?
  initializer_without_templates(name, content, &block)
end
alias_method_chain(:initializer, :templates)

def file_with_templates(name, data = nil, log_action = true, &block)
  data = get_file(name) if data.nil? and not block_given?
  file_without_templates(name, data, log_action, &block)
end
alias_method_chain(:file, :templates)

def mkdir(name)
  run("mkdir -p #{ name.inspect }")
end

require 'erb'
def erb_template(destination)
  source = "#{ destination }.erb"

  log('erb', "Processing '#{ source }' to '#{ destination }' ...")
  file(destination, ERB.new(get_file(source), 0, '-').result(binding))
end

def yaml(filename, default = nil, &block)
  yaml =
    begin
      File.open(filename, 'r') { |file| YAML.load(file) }
    rescue Errno::ENOENT => e
      default
    end

  yield(yaml)
  File.open(filename, 'w') { |file| file.write(YAML.dump(yaml)) }
end

def locale(language_identifier, &block)
  yaml(File.join(%w{config locales}, "#{ language_identifier }.yml"), { language_identifier.to_s => {} }) do |locale|
    block.call(locale[language_identifier])
    locale
  end
end

def javascripts(*filenames)
  filenames.each { |filename| file(File.join(%w{public javascripts}, "#{ filename }.js")) }
end

def images(*filenames)
  filenames.each { |filename| file(File.join(%w{public images}, filename)) }
end

#####################################################################################################################
# RVM helpers
#####################################################################################################################
# Ensures that the command is executed with the appropriate RVM gemset active
def run_with_rvm(command, *args)
  run_without_rvm("bash -l -c 'rvm gemset use #{application_name} && #{command}'", *args)
end
alias_method_chain(:run, :rvm)

# Use to create RVM gemsets
def rvm_create_gemset(name)
  # Don't want the RVM gemset stuff here because we're creating it!
  log('rvm', "Creating gemset '#{ name }' ...")
  run_without_rvm("rvm gemset create #{name}", false)
end

# Use to setup the .rvmrc file to use a specific Ruby version and RVM gemset
def rvm_create_rc(gemset, ruby_version = ENV['RUBY_VERSION'].sub(/-p\d+$/, ''))
  log('rvm', "Creating .rvmrc file to use #{ ruby_version }@#{ gemset }")

  file '.rvmrc', %{
    rvm use #{ruby_version}
    rvm gemset use #{gemset}
  }.strip
end

#####################################################################################################################
# Git helpers
#####################################################################################################################
# Adds to the .gitignore file
def git_ignore(*files)
  log('git', 'Updating .gitignore ...')
  append_file('.gitignore', files.join("\n") << "\n")
end

# Touches .gitignore files in each of the directories
def git_ignore_directories(*directories)
  log('git', 'Putting .gitignore files in some directories ...')
  run("touch #{ directories.map { |d| File.join(d, '.gitignore') }.join(' ') }", false)
end

# Transactional git initialisation
def git_commit(message, path = '.', &block)
  unless File.directory?(File.join(root, '.git'))
    log('git', 'Initializing git repository')
    git(:init)
  end
  yield
  log('git', "Commiting with message #{ message.inspect }")
  git(:add => path)
  git(:commit => "-a -m #{ message.inspect }")
end

#####################################################################################################################
# Bundler helpers
#####################################################################################################################
def bundle(&block)
  generate_gemfile(&block)
  install_gems
end

class Bundle
  class Source
    def initialize(url)
      @url = url
    end

    def contents
      "source #{ @url.inspect }"
    end
  end

  class Gem
    def initialize(name, *args)
      @name, @args = name, args
    end

    def contents
      values = [ @name, *@args ]
      "gem #{ values.map(&:inspect).join(', ') }"
    end
  end

  def initialize(name = nil, &block)
    @name = name
    @sources, @gems, @groups = [], [], []
    instance_eval(&block)
  end

  def source(name)
    @sources << Source.new(name)
  end

  def gem(name, *args)
    @gems << Gem.new(name, *args)
  end

  def group(name, &block)
    @groups << self.class.new(name, &block)
  end

  def contents
    content = ''
    content << "group :#{ @name } do\n" unless @name.nil?
    content << [ @sources, @gems, @groups ].flatten.map(&:contents).join("\n") << "\n"
    content << "end\n" unless @name.nil?
    content
  end
end

def generate_gemfile(&block)
  log 'bundler', 'Updating Gemfile ...'
  append_file('Gemfile', Bundle.new(&block).contents)
end

def install_gems
  log 'bundler', 'Installing gems ...'
  run('bundle install', false)
end

def bundler_install_into_rails
  log 'bundler', 'Setting up Rails to use Bundler ...'

  file('config/preinitializer.rb', left_justify(%Q{
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
  }).strip)

  gsub_file('config/boot.rb', "Rails.boot!", left_justify(%Q{
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
  }).strip)

  git_ignore('.bundle')
end

#####################################################################################################################
# Authentication plugin stuff
#####################################################################################################################
def authentication_install
  # NOTE: Seem to be having loads of problems with script/plugin (through plugin helper) so use git submodule directly
  log('authentication', 'Installing required plugins ...')
  git(:submodule => 'add http://github.com/DocSavage/rails-authorization-plugin.git vendor/plugins/rails-authorization-plugin')
  git(:submodule => 'add ssh://git.internal.sanger.ac.uk/repos/git/psd/sanger_authentication.git vendor/plugins/sanger_authentication')

  log('authentication', 'Setting up default routes ...')
  route 'map.login     "/login",     :controller => "sessions", :action => "index",  :conditions => { :method => :get  }'
  route 'map.login_now "/login/now", :controller => "sessions", :action => "login",  :conditions => { :method => :post }'
  route 'map.logout    "/logout",    :controller => "sessions", :action => "logout", :conditions => { :method => :get  }'

  log('authentication', 'Setting up models ...')
  generate("audited_migration", "add_audits_table")
  generate("role_model", "role")
  generate(:model, "User", "login:string", "cached_cookie:string")

  log('authentication', 'Setting up application infrastructure ...')
  gsub_file('app/controllers/application_controller.rb', 'end', left_justify(%Q{
    # Authentication related stuff ...
    attr_accessor :current_user
    include SangerAuthentication
    before_filter :login_required
    filter_parameter_logging :password, :credential_1
  end
  }))

  locale('en') do |config|
    config['controllers'] ||= {}
    config['controllers'].merge!(
      'sessions' => {
        'messages' => {
          'logged_in'       => 'Logged in successfully.',
          'logged_out'      => 'You have been logged out.',
          'invalid_details' => "Your log in details don't match our records. Please try again."
        },
        'views' => {
          'login' => {
            'button' => 'Login'
          }
        }
      }
    )
  end

  file 'app/models/user.rb'
  file 'app/controllers/sessions_controller.rb'
  file 'app/views/layouts/sessions.html.erb'
  file 'app/views/sessions/login.html.erb'

  compass_stylesheets('sessions')
  javascripts('xml_request')
end

#####################################################################################################################
# Compass helpers
#####################################################################################################################
# Installs compass into the current application
def compass_install
  log('compass', 'Requiring the compass gem ...')
  bundle { gem 'compass', '~>0.10.2' }

  log('compass', 'Installing compass into the application ...')
  run("compass init rails --sass-dir app/stylesheets --css-dir public/stylesheets .")

  # NOTE: This only needs to happen for Rails 2.3 and compass 0.10.2 by the looks of it.
  # http://github.com/chriseppstein/compass/issuesearch?state=closed&q=yui#issue/172
  log('compass', 'Patching compass initialization ...')
  gsub_file('config/compass.rb', 'environment = Compass::AppIntegration::Rails.env', left_justify(%Q{
    environment = Compass::AppIntegration::Rails.env
    extensions_path = 'vendor/plugins/compass_extensions'
  }).strip)
  gsub_file('config/initializers/compass.rb', 'Compass.configure_sass_plugin!', left_justify(%Q{
    Compass.discover_extensions!
    Compass.configure_sass_plugin!
  }).strip)
end

# Installs compass stylesheets
def compass_stylesheets(*stylesheets)
  log('compass', 'Installing compass stylesheets ...')
  stylesheets.each { |stylesheet| file(File.join('app', 'stylesheets', "#{ stylesheet }.scss")) }
end

# Installs a compass plugin from the given URL
def compass_plugin(name, url)
  log('compass', "Installing compass plugin '#{ name }' ...")
  git(:submodule => "add #{ url.inspect } #{ File.join(%w{vendor plugins compass_extensions}, name).inspect }")
end
