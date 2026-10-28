# frozen_string_literal: true

source "https://rubygems.org"

gem "rails", "~> 8.1.4"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[windows jruby]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

gem "nokogiri", "~> 1.16"
gem "httparty", "~> 0.23"
gem "sidekiq", "~> 8.0"
gem "sidekiq-cron", "~> 2.0"

# Headless browser used to render the Blazor-based moose.gg pages
gem "selenium-webdriver", "~> 4.0"

# Runtime support for Sorbet type signatures
gem "sorbet-runtime"

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"

  # Testing framework
  gem "rspec-rails", "~> 8.0"

  # Audits gems for known security defects (use config/bundler-audit.yml to ignore issues)
  gem "bundler-audit", require: false

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false

  # Shopify Ruby style, see https://ruby-style-guide.shopify.dev/
  gem "rubocop-shopify", require: false

  # Static type checking and RBI generation
  gem "sorbet", require: false
  gem "tapioca", require: false
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"
end
