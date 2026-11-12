# frozen_string_literal: true

class EnforcePairedPublishingMediaDimensions < ActiveRecord::Migration[8.2]
  OLD_EXPRESSION = "(width IS NULL AND height IS NULL) OR (width > 0 AND height > 0)"
  NEW_EXPRESSION = "(width IS NULL AND height IS NULL) OR " \
                   "(width IS NOT NULL AND height IS NOT NULL AND width > 0 AND height > 0)"

  def up
    invalid_count = select_value(<<~SQL.squish).to_i
      SELECT count(*) FROM publishing_media_files
      WHERE (width IS NULL) <> (height IS NULL) OR width <= 0 OR height <= 0
    SQL
    if invalid_count.positive?
      raise ActiveRecord::MigrationError,
            "publishing media has #{invalid_count} invalid dimension pairs; repair authoritative metadata before retrying"
    end

    # Replacing both checks in one transaction preserves enforcement on failure. Validation takes
    # a table lock and scans existing rows; deploy only after reviewing the table size and writers.
    safety_assured do
      remove_check_constraint(:publishing_media_files, name: "chk_publishing_media_dimensions")
      add_check_constraint(:publishing_media_files, NEW_EXPRESSION, name: "chk_publishing_media_dimensions")
    end
  end

  def down
    safety_assured do
      remove_check_constraint(:publishing_media_files, name: "chk_publishing_media_dimensions")
      add_check_constraint(:publishing_media_files, OLD_EXPRESSION, name: "chk_publishing_media_dimensions")
    end
  end
end
