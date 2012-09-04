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

Plugins
-------
### Must
* Plugins must add themselves to Gemfile.
* Don't load features for plugins that aren't installed.
* `corvid` bin should also load and expose (namespaced) plugins' tasks.
* Provide ext points
  * test bootstraps
  * test helpers
  * `Gemfile`
  * `Guardfile`
  * code coverage settings

### Should
* Doco on how plugins work, how to write one.
* Test `template/template2` in context of install/update.
* Add visible to Feature and have corvid create install tasks on-the-fly when plugin installed and features not.
* Strip _plugin and _feature from new:xxx names

### Could
* Test Corvid and a plugin both modifying the same file.
* Make corvid:init work via install_plugin?
* `new:plugin NAME` task should create `test/spec/corvid/NAME_bin_spec.rb` which
* `corvid new:feature NAME` should prompts if more than one existing plugin found
