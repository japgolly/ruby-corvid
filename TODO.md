TODO
====
* Is there a point for `environment.rb`?
* Is there a point for `CORVID_ROOT`?
* Check `APP_ROOT` reliance

Patches/Migration/Upgrades TODOs
================================
* Upgrading existing features: migrate each feature from m->n
** Expand versions m->n
** Migrate installed files
** Perform migration steps

* Do 3-way diffs
* Handle merge conflicts

* Process doco
* Clean up code - refactor, rename, doc, proper error msgs

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
