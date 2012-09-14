# MUST
------

### Fix / Enhance Existing Functionality

### New Functionality
* `corvid new:test:*` shouldn't be using latest resources. They should be using `version.yml`
* Allow a plugin to work without need for the Corvid builtin plugin.

### Non-Functional / Under-The-Hood

### Documentation
* Get callbacks into yard.
* Write an _actual_ README.
* Create a demo.



# SHOULD
--------

### Fix / Enhance Existing Functionality
* Fix up `corvid --help` messages
* `.corvid/Gemfile` should check if certain features are installed rather than `Dir.exist?` checks
* Put guard lib stuff in its own group and require 1.3.2+
* Re-eval all the old, initial Corvid template stuff (bootstraps, etc).
* Corvid init should take a project name arg and verify that it's valid.

### New Functionality
* Integration tests. (Like NS: new dir, Guard, Rake, Simplecov)
* `Guardfile` should have the allow for no-project name within test dir structure.
* Provide ext point: test bootstraps
* Provide ext point: test helpers
* Provide ext point: `Gemfile`

### Non-Functional / Under-The-Hood
* Is there a point for `environment.rb`?
* Is there a point for `CORVID_ROOT`?
* Check `APP_ROOT` reliance
* Split `corvid/rake/tasks/test.rb` into unit, spec, all.
* Check transient dependencies. Like do corvid apps really need Thor on _their_ runtime dep list?
* Make corvid:init work via `install_plugin`?

### Documentation
* Doco for potential plugin devs/users
* Doc what is and isn't needed in update() in feature installers



# COULD
-------

### Fix / Enhance Existing Functionality
* Warn if uncommitted changes before install/update. Test with a few vcs systems; at least git and svn.
* Allow `copy_file()` to deploy to a different filename (without breaking patches).
* Test non-ASCII resources.
* Should tasks be organised by content before function? i.e. `project:*, test:*, plugin:*` instead of `init:*, new:*` ![?](question.png)
* Handle cases where installed = n and first version of feature installer is n+1
* Test Corvid and a plugin both modifying the same file.
* `corvid new:feature NAME` should prompts if more than one existing plugin found

### New Functionality
* Provide ext point: `Guardfile`
* Provide ext point: code coverage settings
* Allow different dir structure than default
* Have Corvid provide code analysis (complexity, duplication, etc).
* Performance tests. Maybe also have results checked in so history maintained. ![?](question.png)
* Plugin CLI should load plugin & feature provided tasks when installed.
* Plugin CLI should provide install tasks for uninstalled plugin features (unless disabled by flag in Feature).

### Non-Functional / Under-The-Hood
* Reduce version granularity to feature?

### Documentation

