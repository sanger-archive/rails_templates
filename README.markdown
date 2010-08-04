Rails application templates
===========================
This repository contains any Rails application templates that are used internally by the Production Software team within [The Wellcome Trust Sanger Institute](http://sanger.ac.uk/).

*WARNING:* This is still very much a work in progress at the moment as we're migrating this to github.com.

For people adding a template:
-----------------------------
You should consider using the `template_helpers.rb` file and load it by doing:

    eval(open(File.join(File.dirname(template), 'template_helpers.rb')).read)

As the very first line of your template file.  This gives you a bunch of useful helper methods, especially relating to [RVM](http://rvm.beginrescueend.com/) and [Bundler](http://gembundler.com/).

Third party code included
=========================
The following are (partially) included within this repository:

* prototype.js     - http://prototypejs.org/
* scriptaculous.js - http://script.aculo.us/
* popup.js         - http://www.methods.co.nz/popup/popup.html
* tablekit.js      - http://millstream.com.au/view/code/tablekit/
