source :rubygems
gemspec

# Load Corvid dependencies
eval File.read(File.expand_path '../.corvid/Gemfile', __FILE__)

# Parser for Markdown documentation
group :doc do
  gem 'rdiscount', platforms: :mri
  gem 'kramdown', platforms: :jruby
end

