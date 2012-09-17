source :rubygems

gemspec
gem 'golly-utils', git: 'git://github.com/japgolly/golly-utils.git' # TODO use proper golly-utils

# Testing
group :test do
  gem 'simplecov', require: false
  gem 'guard', '>= 1.3.2', require: false
  gem 'guard-rspec', require: false
  gem 'rb-inotify', '>= 0.8.8', require: false
end

# CI
group :ci do
  gem 'ci_reporter', require: false
end

# Documentation
group :doc do
  gem 'rdiscount', platforms: :mri
  gem 'kramdown', platforms: :jruby
end
gem 'yard', git: 'git://github.com/japgolly/yard.git', branch: 'happy_days', group: :doc # TODO Use proper yard
