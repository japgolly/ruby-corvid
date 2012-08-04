source :rubygems

gemspec
gem 'golly-utils', git: 'git://github.com/japgolly/golly-utils.git' # TODO use proper golly-utils

# Testing
group :test do
  gem 'simplecov', require: false
  gem 'guard-rspec'
end

# CI
group :ci do
  gem 'ci_reporter', require: false
end

# Documentation
group :doc do
  # TODO use proper yard
  #gem 'yard', path: '~/projects/my_forks/yard'
  gem 'yard', git: 'git://github.com/japgolly/yard.git', branch: 'happy_days'
  gem 'rdiscount', platforms: :mri
  gem 'kramdown', platforms: :jruby
end
