# frozen_string_literal: true

require "rails_helper"

# These run a real headless Firefox against local copies of the page markup,
# so they exercise the actual XPath and wait logic without touching moose.gg.
# Needs firefox + geckodriver on the PATH.
RSpec.describe MoosePlayerCountScraper do
  def fixture_url(name)
    "file://#{Rails.root.join("spec/fixtures/pages", name)}"
  end

  it "returns the current player count as an Integer" do
    count = described_class.call(url: fixture_url("players.html"), timeout: 10)

    expect(count).to eq(148)
  end

  it "waits for the count to render client-side" do
    count = described_class.call(url: fixture_url("players_delayed.html"), timeout: 10)

    expect(count).to eq(87)
  end

  it "raises ScrapeError when the count never renders" do
    expect { described_class.call(url: fixture_url("no_players.html"), timeout: 1) }
      .to raise_error(described_class::ScrapeError, /did not render within 1s/)
  end

  it "builds the page URL from the server name" do
    scraper = instance_spy(described_class, call: 1)
    allow(described_class).to receive(:new).and_return(scraper)

    described_class.call(server: "us-monthly")

    expect(described_class).to have_received(:new)
      .with(url: "https://moose.gg/servers/us-monthly", timeout: described_class::TIMEOUT)
  end

  it "quits the browser even when scraping fails" do
    # A real (uninitialised) Driver so the sigs' runtime type checks still pass.
    driver = Selenium::WebDriver::Driver.allocate
    allow(driver).to receive_messages(get: nil, quit: nil, find_elements: [])
    allow(Selenium::WebDriver).to receive(:for).and_return(driver)

    expect { described_class.call(timeout: 1) }.to raise_error(described_class::ScrapeError)
    expect(driver).to have_received(:quit)
  end
end
