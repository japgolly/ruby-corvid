Fix or Enhance Existing Functionality
-------------------------------------
* Fix up `corvid --help` messages
* Warn if uncommitted changes before install/update. Test with a few vcs systems; at least git and svn.
* Test non-ASCII resources.
* `.corvid/Gemfile` should check if certain features are installed rather than `Dir.exist?` checks
* Allow `copy_file()` to deploy to a different filename (without breaking patches).
* Should tasks be organised by content before function? i.e. `project:*, test:*, plugin:*` instead of `init:*, new:*` ![?](question.png)
* Handle cases where installed = n and first version of feature installer is n+1

Documentation
-------------
* Doc the res-patch situation, change process, `rake res:*`, etc.
* Write an _actual_ README.
* Relearn open-source licencing. Tick the legal box. ©

New Functionality
-----------------
* New task: `res:redo`
* Allow different dir structure than default
* Have Corvid provide code stats (LOC, lib vs test, doc/undoc methods/classes etc).
* Have Corvid provide code analysis (complexity, duplication, etc).
* Integration tests. (Like NS: new dir, Guard, Rake, Simplecov)
* Performance tests. Maybe also have results checked in so history maintained. ![?](question.png)
* Add a library feature that adds things like gemspec ![?](question.png)

Non-Functional / Under-The-Hood
-------------------------------
* Is there a point for `environment.rb`?
* Is there a point for `CORVID_ROOT`?
* Check `APP_ROOT` reliance
* In feature installers, is `update()` really needed? Currently it needs increments of `install()` without the `copy_file` stuff. That's stupid...
* Reduce version granularity to feature?

Feature Manifest & Ext Point Support
------------------------------------
* Open ext points to features, not plugins
  * For each installed feature, use a factory to get a feature ext class
    * Give a string
    * Load feature manifest for plugin
      * For corvid, we know the manifest file
      * For plugins, use plugin manager to extract from Plugin
    * Require file specified in feature manifest
    * Get ni/class instance
  * For each feature ext class, iterate from ext point
