# frozen_string_literal: true

module Publishing
  module Docs
    module Com
      class VersionMediaUsage < PublishingRecord
        self.table_name = "publishing_docs_com_version_media_usages"
        include PublishingVersionMediaUsageRecord

        PublishingVersionMediaUsageRecord.configure(self)
      end
    end
  end
end
