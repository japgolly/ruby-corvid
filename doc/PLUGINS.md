Info for Potential Plugin Devs and Users
========================================

## What can I do with plugins?

## What will they do?

## How much effort involved? An idea of the dev/maintenance required.

## What will the experience be like for users?

## Why shouldn't I just use something like Thor?


******

Info for Plugin Developers
==========================

Overview of entities and how they fit together
----------------------------------------------
                          _____________
                          |           |
               +--(0~1)-> | Extension | <-(1)-----+
               |          |___________|           |
               |                                  |
               |                                  |
               |                                  |
           includes                           includes
         ______|_____                       ______|______
         |          |                       |           |
         |          | provides              |           | installed via
         |  Plugin  | -(1)-----------(0~n)- |  Feature  | -(1)-----+
         |          |                       |           |          |
         |__________|                       |___________|          |
             |  |                               |                  |
         has |  | loads                   loads |                  |
    multiple |  |                               |                  |
    versions |  |                               |                  |
          of |  +--------+          +-----------+                 (1)
             |           |          |                        ______|______
             |        ___|__________|___                     |           |
             |        |                |                     | Feature   |
             |        | Task/Generator | ------------------> | Installer |
             |        |________________| invokes             |___________|
             |                  |                                 |
             |                  | uses                            | lives in &
             |                  |                                 | sources templates from
             |                  |                                 |
             |            ______|______                           |
             |            |           |                           |
             +----(0~n)-> | Plugin    | <-------------------------+
                          | Resources |
                          |___________|


How do I author a plugin?
-------------------------
An overview of the process to create a Corvid plugin from scratch is as follows.

1. Create a new Corvid project.
1. Create the plugin.
   This will provide you with a basic-level of functionality.
   Think of a plugin as a container or umbrella for all the functionality you want to inject into users' projects.
1. Create a plugin feature.
   A feature represents a chunk of installable functionality. This is the meat of your product, or the gateway to it.
1. Package up all resources your plugin/features need.
   Resources are generally templates or files that you will install into users' projects.
1. Test.
1. You're done, release your application.

### Create a plugin.
A Corvid plugin project is just a normal Corvid project with the `corvid:plugin` feature installed.

1. Create a Corvid project if you haven't yet.
       corvid init
1. Add plugin development support if you haven't yet.
       corvid init:plugin
1. Generate a new plugin.
       corvid new:plugin <NAME>
1. Customise generated files as required.

### Create a feature.
Once you've created a plugin, you can start creating features.

1. Generate a new feature.
       corvid new:feature <NAME>
1. Customise generated files as required.
1. Add any resources required by the feature installer to the `resources/latest` directory.
1. Bundle up your feature installer and resources.
       bundle exec rake res:new
1. Run tests.

### How do I test?
Running your tests is simple. You just run:
       bundle exec rake test

As for how to write tests, I would recommend this:

1. Put the minimal amount of logic inside resources (i.e. files that will be deployed into users' projects).
   Ideally resources should just include enough code to call your library.
       # Load awesome functionality
       require 'my_plugin/awesome/functionality'
1. Put the functionality you want available to your plugin's users, in a normal class/module, in a normal file in your
   `lib` directory. The fact that it will only be run from another project shouldn't make any kind of different.
1. Test the class/module in the previous step as you would if you were working on any other project.

If you are a little obsessive or there is sufficient risk to warrant integration testing, it's slow but it can be done
quite easily. See tests under Corvid's `test/integration` directory for examples.

How do I extend Corvid functionality?
-------------------------------------
Corvid provides several extension points that allow contributors to jump in and provide their own functionality.
Simply make sure your plugin/feature includes the {Corvid::Extension} module, then implement the extension callback.

Example:
    class MyFeature < Corvid::Feature

      # Use the rake_tasks extension point to load my own tasks.
      rake_tasks {
        require 'my_tasks/doc.rake'
        require 'my_tasks/test.rake'
      }

    end

What are resources?
-------------------
Resources are files that feature installers and generators use. More generally, they are typically files that you want
your feature to copy into a user's project, and templates to generate files with dynamic content.

If you change a file or template once users have already installed it, ideally you would want to be able to push the new
changes out to users. Corvid supports this and does so by bundling up all reasources into a package (called a resource
patch) and giving it a version number. That way when you create a new version of resources, users can update their
installations to your new version of resources to get the latest changes.

### How do I add my own?
To create your own resource patch:

1. Put all of your resources in your project's `resources/latest/' directory.
1. Run the `res:new` rake task.
       bundle exec rake res:new
1. Run tests.

   (You will find a test was generated for you when you ran `corvid new:plugin` that verifies the validity of your
   resource patches).


### What other tools do I have to work with resources and patches?
You get a bunch of rake tasks:
    rake res:diff          # Shows the differences between the latest resource patch and resources/latest.
    rake res:latest        # Deploys the latest version of resources into resources/latest.
    rake res:new           # Create a new resource patch.
    rake res:redo          # Recreate the latest resource patch (USE WITH CARE)

You also get some tests to verify your resource patches. See {Corvid::ResourcePatchTests}.


### How do resource patches work?
See {Corvid::ResPatchManager}.

How does one use my plugin?
---------------------------
1. One installs the gem on their system.
       gem install hot_cows
1. One installs your plugin into their Corvid project.
       hot_cows init
1. Done! Your plugin's other tasks are now exposed via corvid.
       # Examples:
       corvid hot_cows:install:benchmarks
       corvid hot_cows:install:tests

