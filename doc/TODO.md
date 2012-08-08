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
* Split `corvid/rake/tasks/test.rb` into unit, spec, all.

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

Plugins: The Plan
-----------------
* Create a plugin feature
  * Creates new `resources/latest` dir
  * Adds `res` rake tasks
  * Adds rspec feature
  * Adds res-patch validity test
* Feature installation
  * Check that requirements are met.
  * Use plugin resources.
* Plugin installation
  * Check that feature requirements are met.
  * Add name and require-path to `plugins.yml`
  * Install features
* Plugin updating
  * Check requirements already met for latest version of all installed plugin features.
* Create a `new:plugin NAME` task
  1. ensures plugin feature installed
  1. creates `bin/NAME`
  1. creates `lib/NAME/corvid/plugin.rb` which
     * loads and extends {Plugin}
  1. creates `test/spec/corvid/plugin_spec.rb` which
     * loads plugin test-helpers
  1. creates `test/spec/corvid/bin_spec.rb` which
     * tests that the bin script works
* Existing state changes
  * `plugins.yml` contains: `plugin -> :require -> string`
  * `version.yml` update to structure: `plugin -> version` and rename to `versions.yml`
  * `features.yml` and feature names: update to `<plugin>:<name>`
  * `corvid-features/*` to specify dependencies on feature and/or res versions.
* Provide ext points
  * test bootstraps
  * test helpers
  * `Gemfile`
  * `Guardfile`
  * code coverage settings
  * Rake tasks ![Done](done.png)
* Create a plugin bin/CLI delegate
  * `<plugin> init`
  * `<plugin> update`
* Test Corvid and a plugin both modifying the same file.
* Doco on how plugins work, how to write one.
