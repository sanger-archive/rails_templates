desc "Staging release task"
task :staging do
  set :deploy_name, "sdb"
  set :environment, "staging"
  set :rails_env, "staging"
  set :deploy_server, "psd1d"
  setup_local
end
task :production do
  set :deploy_name, "sdb"
  set :environment, "production"
  set :rails_env, "production"
  set :deploy_server, "psd1b"
  setup_local
end

task :setup_local do 
  role :web, "#{deploy_server}.internal.sanger.ac.uk"
  role :app, "#{deploy_server}.internal.sanger.ac.uk"
  role :db,  "#{deploy_server}.internal.sanger.ac.uk", :primary => true
  set :deploy_to, "/software/webapp/#{environment}/#{deploy_name}"
end

