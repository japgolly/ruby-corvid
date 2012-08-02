TODO
====
* Is there a point for `environment.rb`?
* Is there a point for `CORVID_ROOT`?
* Check `APP_ROOT` reliance
* Fix up `corvid --help messages`
* Allow different dir structure than default

ResPatches & Upgrades TODOs
===========================
* Is update() really needed? Currently it needs increments of install() without the `copy_file` stuff. That's stupid...
* Doc the res-patch situation, change process, `rake res:*`, etc.

Plugins
=======
* Doco on how plugins work, how to write one.
* How to install plugin initially?
* How can plugins edit shared resources (eg. `Gemfile`)? Is there a need? Would ext points be better (like with Rake
  tasks)?
* Plugins must be able to contribute to:
  * test bootstraps
  * test helpers
  * `Guardfile`
  * code coverage settings
  * Rake tasks ![Done](done.png)

