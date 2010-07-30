# This contains details of the release of the application
# to remove hard coding throughout the application

# Parts of this file could be dynamically rewritten by
# Capistrano task / Git hooks on deployments / commits

require "ostruct"

RELEASE = OpenStruct.new

RELEASE.application_name = "Test app"
RELEASE.organisation = "Wellcome Trust Sanger Institute"
RELEASE.organisation_link = "http://www.sanger.ac.uk"
RELEASE.major = 1 
RELEASE.iteration = 0
RELEASE.feature = 0
RELEASE.bug_fix = 0
featured = [RELEASE.major, RELEASE.iteration]
featured << RELEASE.feature if RELEASE.feature > 0
RELEASE.featured = featured.join(".")
RELEASE.full = [RELEASE.major, RELEASE.iteration, RELEASE.feature, RELEASE.bug_fix].join(".")
RELEASE.api_version = "0.3"

# SVN rather than git based
#RELEASE.revision = "$Revision$".match(/(\d+)/)[1]
#RELEASE.revised_date = "$Date$".match(/: (.*) \(/)[1]
