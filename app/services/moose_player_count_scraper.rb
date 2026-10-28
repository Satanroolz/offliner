# typed: true
# frozen_string_literal: true

# moose.gg is a Blazor Server app: the player count is filled in over SignalR
# after page load, so it isn't in the initial HTML. We render the page in a
# headless Firefox and read it from the DOM once it appears.
class MoosePlayerCountScraper
  extend T::Sig

  SERVERS_URL = "https://moose.gg/servers"
  DEFAULT_SERVER = "us-main"
  TIMEOUT = 30 # seconds to wait for the count to render

  class ScrapeError < StandardError; end

  class << self
    extend T::Sig

    sig { params(server: String, timeout: Integer, url: String).returns(Integer) }
    def call(server: DEFAULT_SERVER, timeout: TIMEOUT, url: "#{SERVERS_URL}/#{server}")
      new(url: url, timeout: timeout).call
    end
  end

  sig { params(url: String, timeout: Integer).void }
  def initialize(url:, timeout: TIMEOUT)
    @url = url
    @timeout = timeout
  end

  # Returns the current player count as an Integer.
  sig { returns(Integer) }
  def call
    driver = Selenium::WebDriver.for(:firefox, options: browser_options)
    begin
      driver.get(@url)
      wait = Selenium::WebDriver::Wait.new(timeout: @timeout, interval: 0.5)
      text = wait.until { players_text(driver) }
      parse(text)
    rescue Selenium::WebDriver::Error::TimeoutError
      raise ScrapeError, "Player count did not render within #{@timeout}s at #{@url}"
    ensure
      driver.quit
    end
  end

  private

  sig { returns(Selenium::WebDriver::Firefox::Options) }
  def browser_options
    Selenium::WebDriver::Firefox::Options.new(args: ["-headless"])
  end

  # The card reads "Players" followed by an <h5> such as "148 / 200"
  # (current / max). Returns nil until the numbers have rendered.
  sig { params(driver: Selenium::WebDriver::Driver).returns(T.nilable(String)) }
  def players_text(driver)
    label = driver.find_elements(xpath: "//*[contains(@class,'rm-section-title')][normalize-space(.)='Players']").first
    return unless label

    text = label.find_element(xpath: "following-sibling::h5").text
    text if text.match?(/\A\s*\d+/)
  rescue Selenium::WebDriver::Error::NoSuchElementError, Selenium::WebDriver::Error::StaleElementReferenceError
    nil
  end

  sig { params(text: String).returns(Integer) }
  def parse(text)
    text[/\A\s*(\d+)/, 1]&.to_i or raise ScrapeError, "Could not parse player count from #{text.inspect}"
  end
end
