source :rubygems

gemspec

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
  gem 'yard'
  gem 'rdiscount', platforms: :mri
  gem 'kramdown', platforms: :jruby
end
