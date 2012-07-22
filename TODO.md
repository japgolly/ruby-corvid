TODO
====
* Is there a point for `environment.rb`?
* Is there a point for `CORVID_ROOT`?
* Check `APP_ROOT` reliance

Patches/Migration/Upgrades TODOs
================================
* Process doco
* Clean up code - refactor, rename, doc, proper error msgs
* Features stored in .corvid/features.yml
* Version specified in .corvid/version.yml
* Code like in generators stored in templated corvid_migration-{feature}.rb which defines (void*)(version)
* Upgrading existing features: migrate each feature from m->n
* Adding new features: add to features.yml, migrate from 0->m
* Make .corvid/Gemfile static rather than a template
* Delete templates/
* rak res:reset and/or res:explode - Restore resources/latest to latest patch
* Handle merge conflicts

### Done
* When exploding, apply patch for 0-n then apply n-1, n-2, etc.
* rak res:new
* create real res patches based on git history
* rak res:diff
