# template.rb
run "rm public/index.html"
app_name = ask('Name of application')
deploy_name = ask('Deploy name')

ENVIRONMENTS = ['development', 'training', 'staging', 'next_release', 'production']

#git :init
#git :add => "."
#git :commit => "-a -m 'Initial commit'"

# TODO: Add Capistrano things
# TODO: Add nginx things
# TODO: Freeze rails and gemS
