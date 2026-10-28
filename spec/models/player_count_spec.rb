# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlayerCount do
  subject(:player_count) { described_class.new(server: "us-main", count: 140, started_at: 5.seconds.ago, ended_at: Time.current) }

  it { is_expected.to be_valid }

  it "requires a server" do
    player_count.server = nil
    expect(player_count).not_to be_valid
  end

  it "requires a count" do
    player_count.count = nil
    expect(player_count).not_to be_valid
  end

  it "rejects negative counts" do
    player_count.count = -1
    expect(player_count).not_to be_valid
  end

  it "rejects non-integer counts" do
    player_count.count = 1.5
    expect(player_count).not_to be_valid
  end

  it "accepts zero players" do
    player_count.count = 0
    expect(player_count).to be_valid
  end

  it "requires started_at and ended_at" do
    player_count.started_at = nil
    player_count.ended_at = nil

    expect(player_count).not_to be_valid
    expect(player_count.errors.attribute_names).to contain_exactly(:started_at, :ended_at)
  end
end
