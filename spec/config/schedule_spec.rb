# frozen_string_literal: true

require "rails_helper"

RSpec.describe "config/schedule.yml" do
  let(:schedule) { YAML.load_file(Rails.root.join("config/schedule.yml")) }

  it "schedules the player count scrape every 30 minutes" do
    entry = schedule.fetch("scrape_player_count")

    expect(entry["class"]).to eq("ScrapePlayerCountJob")
    expect(entry["cron"]).to eq("*/30 * * * *")
    expect(entry["args"]).to eq(["us-main"])
  end

  it "only references jobs and cron expressions sidekiq-cron accepts" do
    schedule.each do |name, entry|
      job = Sidekiq::Cron::Job.new(entry.merge("name" => name))

      expect(job).to be_valid, "#{name}: #{job.errors.join(', ')}"
      expect(entry["class"].constantize).to be < Sidekiq::Job
    end
  end
end
