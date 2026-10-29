# frozen_string_literal: true

require "rails_helper"

RSpec.describe "POST /api/v1/scrapes", type: :request do
  it "enqueues a scrape of us-main by default" do
    expect { post "/api/v1/scrapes" }.to change(ScrapePlayerCountJob.jobs, :size).by(1)

    expect(response).to have_http_status(:accepted)
    expect(ScrapePlayerCountJob.jobs.last["args"]).to eq(["us-main"])
    expect(response.parsed_body).to include("server" => "us-main", "status" => "enqueued", "job_id" => ScrapePlayerCountJob.jobs.last["jid"])
  end

  it "enqueues a scrape of the given server" do
    post "/api/v1/scrapes", params: { server: "us-monthly" }, as: :json

    expect(response).to have_http_status(:accepted)
    expect(ScrapePlayerCountJob.jobs.last["args"]).to eq(["us-monthly"])
  end

  it "rejects a server name that isn't a slug" do
    expect { post "/api/v1/scrapes", params: { server: "../admin" }, as: :json }
      .not_to change(ScrapePlayerCountJob.jobs, :size)

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.parsed_body).to have_key("error")
  end

  it "rejects a non-string server" do
    post "/api/v1/scrapes", params: { server: ["us-main"] }, as: :json

    expect(response).to have_http_status(:unprocessable_content)
  end
end
