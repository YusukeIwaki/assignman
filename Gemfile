source 'https://rubygems.org'

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem 'rails', '~> 8.0.2'
# CSV processing library
gem 'csv'
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem 'propshaft'
# Use sqlite3 for development and test, postgresql for production
gem 'pg', '~> 1.1', group: :production
gem 'sqlite3', '~> 2.0', group: %i[development test]
# Use the Puma web server [https://github.com/puma/puma]
gem 'puma', '>= 5.0'

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[windows jruby]

group :development, :test do
  gem 'annotaterb'
  gem 'pry-byebug'
  gem 'rubocop', '~> 1.57', require: false
  gem 'rubocop-rails', '~> 2.22', require: false
  gem 'rubocop-rspec', '~> 2.25', require: false
end

group :test do
  gem 'factory_bot_rails', '~> 6.4'
  gem 'rspec-rails', '~> 7.0'
  gem 'capybara'
  gem 'capybara-playwright-driver'
end
