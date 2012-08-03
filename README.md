# Corvid [![Build Status](https://secure.travis-ci.org/japgolly/corvid.png?branch=master)](http://travis-ci.org/japgolly/corvid) [![Dependency Status](https://gemnasium.com/japgolly/corvid.png)](https://gemnasium.com/japgolly/corvid)

This README will be written properly soon.

Features
--------
*	Structure
	* `test`
	* `target`
*	Code generators
	* Unit tests
	* Specs
*	Bunch of managed rake tasks
*	YARD doc
*	Testing
	* Bootstraps
	* Organisation (same as structure)
	* Auto-load helpers
	* Auto-load test libraries
	* Test library segregation
	* Warn about unclosed transactions
	* Guard setup
*	Code coverage
	* Auto-enable with `coverage` environment variable.
	* Ignore non-code LOC.
	* Include source files that weren't loaded (require'd)
*   Via plugins, allows yourself and others to get all the glue and customisation, the additional functionality written
    once then easily distribute it to your projects.
*   Upgrade-patching.
    * Corvid can update. No need to ever replace manually.
    * Patches user-modified resources.


TODO
----
{file:doc/TODO.md TODOs are here}.
