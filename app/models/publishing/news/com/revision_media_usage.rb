# frozen_string_literal: true

module Publishing
  module News
    module Com
      class RevisionMediaUsage < PublishingRecord
        self.table_name = "publishing_news_com_revision_media_usages"
        include PublishingRevisionMediaUsageRecord

        PublishingRevisionMediaUsageRecord.configure(self)
      end
    end
  end
end
