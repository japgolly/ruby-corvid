Fix Existing Functionality
--------------------------
* Fix up `corvid --help` messages

Documentation
-------------
* Doc the res-patch situation, change process, `rake res:*`, etc.

New Functionality
-----------------
* Allow different dir structure than default

Non-Functional / Under-The-Hood
-------------------------------
* Is there a point for `environment.rb`?
* Is there a point for `CORVID_ROOT`?
* Check `APP_ROOT` reliance
* In feature installers, is `update()` really needed? Currently it needs increments of install() without the `copy_file` stuff. That's stupid...
