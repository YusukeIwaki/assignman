require 'capybara/rspec'
require 'capybara-playwright-driver'

Capybara.register_driver(:my_playwright) do |app|
  options = { browser_type: :chromium }
  if ["0", "false"].include?(ENV['HEADLESS'])
    # Execute with local installed Chrome Browser
    options[:channel] = 'chrome'
    options[:headless] = false
  end
  Capybara::Playwright::Driver.new(app, **options)
end

Capybara.default_driver = :my_playwright
Capybara.javascript_driver = :my_playwright

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by :my_playwright
  end
end
