# frozen_string_literal: true

module Publishing
  module Help
    module Org
      class EntryVersion < PublishingRecord
        self.table_name = "publishing_help_org_entry_versions"
        include PublishingEntryVersionRecord

        has_many :restored_revisions,
                 class_name: "Publishing::Help::Org::EntryRevision",
                 foreign_key: :restored_from_version_id,
                 inverse_of: :restored_from_version,
                 dependent: :restrict_with_exception

        validates :sequence, uniqueness: { scope: :entry_id }, on: :create
        validates :entry_revision_id, uniqueness: true, on: :create
        validates :created_by_operator_public_id, length: { maximum: 21 }
        # Unique indexes that include the primary key back composite references; checked only for an explicit id.
        validates :id, uniqueness: { scope: %i(entry_id) }, allow_nil: true, if: :will_save_change_to_id?
        validates :id, uniqueness: { scope: %i(locale) }, allow_nil: true, if: :will_save_change_to_id?
      end
    end
  end
end
