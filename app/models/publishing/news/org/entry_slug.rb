# frozen_string_literal: true

module Publishing
  module News
    module Org
      class EntrySlug < PublishingRecord
        self.table_name = "publishing_news_org_entry_slugs"
        include PublishingEntrySlugRecord

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
