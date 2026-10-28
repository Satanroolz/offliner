# frozen_string_literal: true

namespace :player_count do
  desc "Enqueue a Sidekiq job that scrapes and stores a moose.gg server's player count (default: us-main)"
  task :enqueue, [:server] => :environment do |_task, args|
    puts "Enqueued job #{ScrapePlayerCountJob.perform_async(*args.to_a)}"
  end

  desc "Scrape and store the player count right now (no Sidekiq) and print it"
  task :now, [:server] => :environment do |_task, args|
    puts ScrapePlayerCountJob.new.perform(*args.to_a)
  end
end
