New Plugin Creation Process
---------------------------
1. `corvid init:project`
1. Create gemspec.
1. `corvid init:plugin` which
   * Creates new `resources/latest` dir
   * Adds `res` rake tasks
   * Adds rspec feature
   * Adds res-patch validity test
1. `corvid new:plugin NAME` which
   * creates `bin/NAME`
   * creates `lib/corvid/NAME_plugin.rb` which
     * loads and extends {Plugin}
   * creates `test/spec/corvid/NAME_plugin_spec.rb` which
     * loads plugin test-helpers
   * creates `test/spec/corvid/NAME_bin_spec.rb` which
     * tests that the bin script works
   * creates `test/spec/corvid/NAME_features_spec.rb`
1. `corvid new:plugin:feature NAME` which
   * creates `resources/latest/corvid-features/NAME.rb`
   * creates `lib/corvid/NAME_feature.rb`
   * adds it to the plugin manifest (`lib/corvid/????_plugin.rb`)
1. Put resources (if any) in `resources/latest` and call `res:new`
1. Edit plugin and test.


Plugin Installation Process
---------------------------
1. Check if already installed.
1. Check that feature requirements are met.
1. Add name and require-path to `plugins.yml`
1. Add feature(s) normally.
   1. Check if feature installed.
   1. Check requirements are met.
   1. Install, either to newest version of version of last used **plugin** resources.
   1. Update `features.yml`
   1. Update `versions.yml`

Plugin Update Process
---------------------
1. Confirm plugin installed and installed-version isn't latest.
1. Check requirements already met for latest version of all installed plugin features.
1. Update all features provided by plugin.
   1. Check requirements are met.
   1. Update features.
   1. Update `versions.yml`


Plugin Extention Points
-----------------------
* test bootstraps
* test helpers
* `Gemfile`
* `Guardfile`
* code coverage settings
* Rake tasks
