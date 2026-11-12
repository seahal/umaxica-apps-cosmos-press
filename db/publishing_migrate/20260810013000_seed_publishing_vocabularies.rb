# frozen_string_literal: true

require_relative "../migration_support/publishing_schema"

class SeedPublishingVocabularies < ActiveRecord::Migration[8.2]
  DEFINITIONS = [
    %w(category single_hierarchical Category),
    %w(tag multiple_ordered_flat Tag),
  ].freeze

  def up
    safety_assured do
      PublishingSchema::FAMILIES.each do |surface, audience|
        table = "publishing_#{surface}_#{audience}_vocabularies"
        DEFINITIONS.each do |key, kind, internal_name|
          public_id = "substr(md5('publishing_vocabulary:#{surface}/#{audience}/#{key}'), 1, 21)"
          execute(<<~SQL.squish)
            INSERT INTO #{table} (public_id, key, kind, internal_name, created_at, updated_at)
            VALUES (#{public_id}, '#{key}', '#{kind}', '#{internal_name}', now(), now())
            ON CONFLICT (key) DO NOTHING
          SQL
        end
      end
    end
  end

  def down
    # Vocabulary identities survive retirement and may already own historical assignments.
    raise ActiveRecord::IrreversibleMigration, "publishing vocabularies are retired by archiving, never deleted"
  end
end
