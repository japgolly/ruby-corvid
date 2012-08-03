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

Plugins: The Plan
-----------------
* Provide ext points
  * test bootstraps
  * test helpers
  * `Gemfile`
  * `Guardfile`
  * code coverage settings
  * Rake tasks ![Done](done.png)
* Plugins can add features
  * `version.yml` update to structure: `plugin -> :resources -> version`
  * `features.yml` and feature names: update to `<plugin>:<name>`
  * Rake tasks for plugin development (eg. res-patch creation)
* Plugins and/or features can require other features to already be installed.
* Provide template bin script then passes to internal plugin CLI.
  * `<plugin> init`
  * `<plugin> update`
* Test Corvid and a plugin both modifying the same file.
* Doco on how plugins work, how to write one.
