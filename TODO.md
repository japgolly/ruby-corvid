TODO
====
* Is there a point for `environment.rb`?
* Is there a point for `CORVID_ROOT`?
* Check `APP_ROOT` reliance
* Fix up `corvid --help messages`
* Allow different dir structure than default

Patches/Migration/Upgrades TODOs
================================
* Is update() really needed? Currently it needs increments of install() - the copy_file stuff. That's stupid...
* Make corvid-features use callbacks ??
* Do 3-way diffs
* Handle merge conflicts

* Process doco
* Clean up code - refactor, rename, doc, proper error msgs
* Check all TODOs

### Done
* When exploding, apply patch for 0-n then apply n-1, n-2, etc.
* rak res:new
* create real res patches based on git history
* rak res:diff
* rak res:latest
* Make .corvid/Gemfile static rather than a template
* Delete templates/
* Make generators use res patches
* Version specified in .corvid/version.yml
* Features stored in .corvid/features.yml
* Code for features stored in resources under corvid-features/-{feature}.rb which defines install()
* Adding new features: add to features.yml, migrate from 0->m
* Upgrading existing features: migrate each feature from m->n
  * Expand versions m->n
  * Migrate installed files
  * Perform migration steps
* Add tests that ensure upgrades from 1..latest == same as latest install
* Add upgrade deletion tests
