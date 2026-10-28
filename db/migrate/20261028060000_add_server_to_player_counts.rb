# frozen_string_literal: true

class AddServerToPlayerCounts < ActiveRecord::Migration[8.1]
  def change
    # Rows recorded before this column existed came from the wrong server and
    # were deleted by hand, so the table is empty and NOT NULL is safe.
    add_column :player_counts, :server, :string, null: false

    remove_index :player_counts, :started_at
    add_index :player_counts, [:server, :started_at]
  end
end
