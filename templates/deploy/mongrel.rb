namespace :deploy do

  namespace :cluster do
    task :start, :roles => :app do
      run "mongrel_rails cluster::start -C #{deploy_to}/current/deploy/server_#{environment}.yml"
    end

    task :restart, :roles => :app do
      run "mongrel_rails cluster::restart -C #{deploy_to}/current/deploy/server_#{environment}.yml"
    end

    task :stop, :roles => :app do
      run "mongrel_rails cluster::stop -C #{deploy_to}/current/deploy/server_#{environment}.yml"
    end
  end

  desc "Disable requests to the app, show maintenance page"
  task :disable_web, :roles => :app do
    run "cp #{current_path}/public/maintenance.html  #{deploy_to}/system/maintenance.html"
  end

  desc "Re-enable the web server by deleting any maintenance file"
  task :enable_web, :roles => :app do
    run "rm #{deploy_to}/system/maintenance.html"
  end

  desc "Custom restart task for mongrel cluster"
  task :restart, :roles => :app, :except => { :no_release => true } do
    deploy.cluster.restart
  end

  desc "Custom start task for mongrel cluster"
  task :start, :roles => :app do
    deploy.cluster.start
  end

  desc "Custom stop task for mongrel cluster"
  task :stop, :roles => :app do
    deploy.cluster.stop
  end
end
