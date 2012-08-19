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
* Check transient dependencies. Like do corvid apps really need Thor on _their_ runtime dep list?
* Separate client and core stuff in corvid dir stucture. `guard.rb` and `plugin.rb` shouldn't be beside each other.

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
* ![Done](done.png) Plugin installation
  * ![Done](done.png) Add ability to install plugins.
  * ![Done](done.png) Add name and require-path to `plugins.yml`
  * ![TODO](pin-red.png) Install features on plugin installation.
* ![Done](done.png) Create a `new:plugin NAME` task
  * ![TODO](pin-red.png) ensures plugin feature installed
  * ![Done](done.png) creates `lib/corvid/NAME_plugin.rb` which
  * ![Done](done.png) creates `test/spec/corvid/NAME_plugin_spec.rb` which
  * ![Done](done.png) creates `bin/NAME`
  * ![TODO](pin-blue.png) creates `test/spec/corvid/NAME_bin_spec.rb` which
* ![Done](done.png) `corvid new:plugin:feature NAME` which
  * ![Done](done.png) finds an existing plugin
    * ![Done](done.png) uses one if found
    * ![TODO](pin-yellow.png) prompts if more than one
  * ![Done](done.png) creates `resources/latest/corvid-features/NAME.rb`
  * ![Done](done.png) creates `lib/corvid/NAME_feature.rb`
  * ![TODO](pin-blue.png) creates `test/spec/corvid/NAME_features_spec.rb`
  * ![Done](done.png) adds feature to the plugin manifest (`lib/corvid/????_plugin.rb`)
* ![Done](done.png) Create a plugin bin/CLI delegate
  * ![Done](done.png) `<plugin> install`
  * ![Done](done.png) `<plugin> update`

#### Modify
* Feature installation
  * ![Done](done.png) Check that requirements are met.
  * ![TODO](pin-red.png) Use plugin resources.
* ![Done](done.png) Feature updating
  * ![Done](done.png) Update plugins' features.
  * ![TODO](pin-red.png) Check requirements already met for latest version of all installed plugin features.
* Existing state changes
  * ![Done](done.png) `plugins.yml` contains: `plugin -> :require -> string`
  * ![Done](done.png) `version.yml` update to structure: `plugin -> version` and rename to `versions.yml`
  * ![Done](done.png) `features.yml` and feature names: update to `<plugin>:<name>`
  * ![Done](done.png) `corvid-features/*` to specify dependencies on feature and/or res versions.
* ![Done](done.png) Provide ext points
  * test bootstraps
  * test helpers
  * `Gemfile`
  * `Guardfile`
  * code coverage settings
  * ![Done](done.png) Rake tasks
* ![TODO](pin-red.png) `corvid` bin should also load and expose (namespaced) plugins' tasks.
* ![Done](done.png) Make `init:project` add corvid to `plugins.yml` and delete (most) special built-in logic.
  Should only load built-in if no `plugins.yml` found.
* ![TODO](pin-red.png) Don't load feature for plugins that aren't installed.

#### Other
* Doco on how plugins work, how to write one.
* Test Corvid and a plugin both modifying the same file.
* Test `template/template2` in context of install/update.
