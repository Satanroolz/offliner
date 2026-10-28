# typed: true
# frozen_string_literal: true

class ScrapePlayerCountJob
  extend T::Sig
  include Sidekiq::Job

  sidekiq_options queue: "default", retry: 3

  sig { params(server: String).returns(Integer) }
  def perform(server = MoosePlayerCountScraper::DEFAULT_SERVER)
    started_at = Time.current
    count = MoosePlayerCountScraper.call(server: server)
    record = PlayerCount.create!(server: server, count: count, started_at: started_at, ended_at: Time.current)

    Rails.logger.info("[ScrapePlayerCountJob] server=#{server} players=#{record.count}")
    record.count
  end
end
