# frozen_string_literal: true

require "rails_helper"

RSpec.describe ScrapePlayerCountJob do
  after { travel_back }

  describe "#perform" do
    it "stores the scraped count with start and end timestamps" do
      start = Time.zone.local(2026, 10, 28, 12, 0, 0)
      travel_to(start)
      allow(MoosePlayerCountScraper).to receive(:call) do
        travel 5.seconds
        148
      end

      expect { described_class.new.perform }.to change(PlayerCount, :count).by(1)

      record = PlayerCount.last
      expect(record.count).to eq(148)
      expect(record.started_at).to be_within(0.001).of(start)
      expect(record.ended_at).to be_within(0.001).of(start + 5.seconds)
    end

    it "scrapes and records us-main by default" do
      allow(MoosePlayerCountScraper).to receive(:call).and_return(10)

      described_class.new.perform

      expect(MoosePlayerCountScraper).to have_received(:call).with(server: "us-main")
      expect(PlayerCount.last.server).to eq("us-main")
    end

    it "scrapes and records the given server" do
      allow(MoosePlayerCountScraper).to receive(:call).and_return(10)

      described_class.new.perform("us-monthly")

      expect(MoosePlayerCountScraper).to have_received(:call).with(server: "us-monthly")
      expect(PlayerCount.last.server).to eq("us-monthly")
    end

    it "returns the count" do
      allow(MoosePlayerCountScraper).to receive(:call).and_return(42)

      expect(described_class.new.perform).to eq(42)
    end

    it "stores nothing and re-raises when the scrape fails" do
      allow(MoosePlayerCountScraper).to receive(:call).and_raise(MoosePlayerCountScraper::ScrapeError, "boom")

      expect { described_class.new.perform }.to raise_error(MoosePlayerCountScraper::ScrapeError)
      expect(PlayerCount.count).to eq(0)
    end
  end

  describe "Sidekiq" do
    it "enqueues onto the default queue" do
      expect { described_class.perform_async }.to change(described_class.jobs, :size).by(1)
      expect(described_class.jobs.last["queue"]).to eq("default")
    end

    it "runs end to end when processed" do
      allow(MoosePlayerCountScraper).to receive(:call).and_return(99)

      Sidekiq.testing!(:inline) { described_class.perform_async }

      expect(PlayerCount.pick(:count)).to eq(99)
    end
  end
end
