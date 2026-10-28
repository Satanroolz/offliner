# typed: true
# frozen_string_literal: true

class PlayerCount < ApplicationRecord
  validates :server, :count, :started_at, :ended_at, presence: true
  validates :count, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
end
