require "test_helper"

Capybara.enable_aria_label = true

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1440, 900 ] do |options|
    options.binary = ENV["CHROME_BIN"] if ENV["CHROME_BIN"].present?
  end
end
