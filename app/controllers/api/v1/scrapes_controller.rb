# typed: true
# frozen_string_literal: true

module Api
  module V1
    class ScrapesController < ApplicationController
      # The server name is interpolated into the scrape URL, so keep it to slug characters.
      SERVER_FORMAT = /\A[a-z0-9-]+\z/

      def create
        server = params.fetch(:server, MoosePlayerCountScraper::DEFAULT_SERVER)

        unless server.is_a?(String) && server.match?(SERVER_FORMAT)
          return render json: { error: "server must be lowercase letters, digits and hyphens" },
            status: :unprocessable_content
        end

        job_id = ScrapePlayerCountJob.perform_async(server)
        render json: { job_id: job_id, server: server, status: "enqueued" }, status: :accepted
      end
    end
  end
end
