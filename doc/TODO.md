Fix or Enhance Existing Functionality
-------------------------------------
* Fix up `corvid --help` messages
* Warn if uncommitted changes before install/update. Test with a few vcs systems; at least git and svn.
* Test non-ASCII resources.
* `.corvid/Gemfile` should check if certain features are installed rather than `Dir.exist?` checks
* Allow `copy_file()` to deploy to a different filename (without breaking patches).
* Should tasks be organised by content before function? i.e. `project:*, test:*, plugin:*` instead of `init:*, new:*` ![?](question.png)

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
