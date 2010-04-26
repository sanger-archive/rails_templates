require 'date'
task :checkit do
	env = @variables[:environment]
	raise Exception, "no environment specified" unless env

#	branch = @variables[:branch]
#	raise Exception, "no branch specified" unless branch

	#TODO move that in a other task, before
	branch = find_current_branch
	@variables[:branch]= branch
	if branch =~ /([^\/]+)\/([^\/]+)/
		remote, branch = [$1, $2]
	else
		remote = 'origin'
	end
	now = DateTime.now
	tag_name =  compute_tag_stamp(now, env)
	current_commit = find_commit(branch, remote)


	raise Exception, "your current version is different from what you are trying to deploy. Maybe you have forgotten to push your modifications. Otherwise, checkout the version you are willing to deploy." unless diff_version("HEAD", current_commit)

	#for the tagit task
	@last_tag = "#{env}/last"
	@tag_name = tag_name
	@current_commit = current_commit
	@remote = remote

end
task :tagit do
	tag_remotely(@tag_name, @current_commit, @remote)
	tag_remotely(@last_tag, @tag_name, @remote, '-f')
end

def find_current_branch
	`git branch | sed -n 's/^\\* //p'`.chomp
end

def compute_tag_stamp(date,environment_name)
	date.strftime "#{environment_name}/%Y-%m-%d/%H-%M-%S"
end

def diff_version(ref1, ref2)
	system "git diff --quiet #{ref1} #{ref2}"
end

def find_commit(branch, remote)
	#TODO see if capistrano can do it.
	system "git fetch #{remote} #{branch}"
	"#{remote}/#{branch}"
end

def tag_remotely(tag_name, commit_name, remote, options='')
	system "git tag #{options} #{tag_name} #{commit_name}"
	system "git push #{remote} #{tag_name}"

end


def remove_tag_remotely(tag_name, remote)
	system "git push :#{remote} #{tag_name}"
end

before"deploy:update_code", :checkit
after"deploy", :tagit


