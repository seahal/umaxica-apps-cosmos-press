# frozen_string_literal: true

module Publishing
  module Docs
    module App
      class EntrySlug < PublishingRecord
        self.table_name = "publishing_docs_app_entry_slugs"
        include PublishingEntrySlugRecord

        PublishingEntrySlugRecord.configure(self)

        validates :slug, uniqueness: { scope: :locale }
        validates :entry_id, uniqueness: { conditions: -> { where(state: "canonical") } },
                             if: -> { state == "canonical" }
        validates :entry_id, uniqueness: { conditions: -> { where(state: "reserved") } },
                             if: -> { state == "reserved" }

        validates :slug, exclusion: { in: [nil] }
      end
    end
  end
end
