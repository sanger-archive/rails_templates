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
  append_file('.gitignore', files.join("\n"))
end

# Touches .gitignore files in each of the directories
def git_ignore_directories(*directories)
  log('git', 'Putting .gitignore files in some directories ...')
  run("touch #{ directories.map { |d| File.join(d, '.gitignore') }.join(' ') }", false)
end

#####################################################################################################################
# Bundler helpers
#####################################################################################################################
def bundler_install(&block)
  setup_rails_for_bundler
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
    content << [ @sources, @gems, @groups ].flatten.map(&:contents).join("\n")
    content << "end" unless @name.nil?
    content
  end
end

def generate_gemfile(&block)
  log 'bundler', 'Generating Gemfile ...'
  file('Gemfile', Bundle.new(&block).contents)
end

def install_gems
  log 'bundler', 'Installing gems ...'
  run('bundle install', false)
end

def setup_rails_for_bundler
  log 'bundler', 'Setting up Rails to use Bundler ...'

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

  git_ignore('.bundler')
end

#####################################################################################################################
# Authentication plugin stuff
#####################################################################################################################
def authentication_install
  log('authentication', 'Installing required plugins ...')
  plugin('rails-authorization-plugin', :git => 'http://github.com/DocSavage/rails-authorization-plugin.git')
  plugin('sanger_authentication',      :git => 'ssh://git.internal.sanger.ac.uk/repos/git/psd/sanger_authentication.git')

  log('authentication', 'Setting up default routes ...')
  route 'map.login "/login", :controller => "sessions", :action => "login"'
  route 'map.logout "/logout", :controller => "sessions", :action => "logout"'

  log('authentication', 'Setting up models ...')
  generate("audited_migration", "add_audits_table")
  generate("role_model", "role")
  generate(:model, "User", "login:string", "cached_cookie:string")

  log('authentication', 'Setting up application infrastructure ...')
  file 'app/models/user.rb'
  file 'app/controllers/sessions_controller.rb'
  file 'app/views/layouts/sessions.html.erb'
  file 'app/views/sessions/login.html.erb'
  file 'public/stylesheets/sessions.css'
end
