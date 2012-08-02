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
* Plugins must be able to contribute to:
  * test bootstraps
  * test helpers
  * project dependencies / `Gemfile`
  * `Guardfile`
  * code coverage settings
  * Rake tasks ![Done](done.png)
  * project file system (i.e. add new files, create new dirs, etc).
* Plugins must be able to perform the following with resources:
  * mkdir
  * add own
  * remove own
  * edit own
  * modify client's ![?](question.png)
  * modify corvid's ![?](question.png)
  * modify other plugin's ![?](question.png)
