# frozen_string_literal: true

class CreatePlayerCounts < ActiveRecord::Migration[8.1]
  def change
    create_table :player_counts do |t|
      t.integer :count, null: false
      t.datetime :started_at, null: false
      t.datetime :ended_at, null: false

      t.timestamps
    end

    add_index :player_counts, :started_at
  end
end
