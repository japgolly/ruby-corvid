Fix or Enhance Existing Functionality
-------------------------------------
* Fix up `corvid --help` messages
* Warn if uncommitted changes before install/update. Test with a few vcs systems; at least git and svn.
* Test non-ASCII resources.
* `.corvid/Gemfile` should check if certain features are installed rather than `Dir.exist?` checks
* Allow `copy_file()` to deploy to a different filename (without breaking patches).
* Should tasks be organised by content before function? i.e. `project:*, test:*, plugin:*` instead of `init:*, new:*` ![?](question.png)
* Handle cases where installed = n and first version of feature installer is n+1
* `bin/corvid` shouldn't just be loading everything. It should use `plugins.yml` to determine.
* `corvid new:test:*` shouldn't be using latest resources. They should be using `version.yml`

Documentation
-------------
* Doc the res-patch situation, change process, `rake res:*`, etc.
* Write an _actual_ README.
* Relearn open-source licencing. Tick the legal box. ©

New Functionality
-----------------
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

Plugins: The Plan
-----------------
#### New
* ![Done](done.png) Features should be able to contribute extensions.
  * ![Done](done.png) Create extension points.
  * ![Done](done.png) Create feature manager.
* ![Done](done.png) Create a corvid `plugin` feature
  * ![Done](done.png) Creates new `resources/latest` dir
  * ![Done](done.png) Adds `res` rake tasks
  * ![Done](done.png) Adds rspec feature
  * ![Done](done.png) Adds res-patch validity test
* Plugin installation
  * Add ability to install plugins.
  * Check that feature requirements are met.
  * Add name and require-path to `plugins.yml`
  * Install features.
* ![Done](done.png) Create a `new:plugin NAME` task
  * ensures plugin feature installed
  * ![Done](done.png) creates `lib/corvid/NAME_plugin.rb` which
  * ![Done](done.png) creates `test/spec/corvid/NAME_plugin_spec.rb` which
  * creates `bin/NAME`
  * creates `test/spec/corvid/NAME_bin_spec.rb` which
* `corvid new:plugin:feature NAME` which
  * finds an existing plugin
    * prompts/fails if none
    * prompts if more than one
  * creates `resources/latest/corvid-features/NAME.rb`
  * creates `lib/corvid/NAME_feature.rb`
  * creates `test/spec/corvid/NAME_features_spec.rb`
  * adds feature to the plugin manifest (`lib/corvid/????_plugin.rb`)
* Create a plugin bin/CLI delegate
  * `<plugin> init`
  * `<plugin> update`

#### Modify
* Feature installation
  * Check that requirements are met.
  * Use plugin resources.
* Feature updating
  * Update plugins' features.
  * Check requirements already met for latest version of all installed plugin features.
* Existing state changes
  * ![Done](done.png) `plugins.yml` contains: `plugin -> :require -> string`
  * `version.yml` update to structure: `plugin -> version` and rename to `versions.yml`
  * `features.yml` and feature names: update to `<plugin>:<name>`
  * `corvid-features/*` to specify dependencies on feature and/or res versions.
* ![Done](done.png) Provide ext points
  * test bootstraps
  * test helpers
  * `Gemfile`
  * `Guardfile`
  * code coverage settings
  * ![Done](done.png) Rake tasks
* `corvid` bin should also load and expose (namespaced) plugins' tasks.
* ![Done](done.png) Make `init:project` add corvid to `plugins.yml` and delete (most) special built-in logic.
  Should only load built-in if no `plugins.yml` found.

#### Other
* Doco on how plugins work, how to write one.
* Test Corvid and a plugin both modifying the same file.

