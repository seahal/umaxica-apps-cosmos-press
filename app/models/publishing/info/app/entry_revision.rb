# frozen_string_literal: true

module Publishing
  module Info
    module App
      class EntryRevision < PublishingRecord
        self.table_name = "publishing_info_app_entry_revisions"
        include PublishingEntryRevisionRecord

        has_many :current_entries, class_name: "Publishing::Info::App::Entry",
                                   foreign_key: :current_revision_id, inverse_of: :current_revision,
                                   dependent: :restrict_with_exception
        has_many :restored_revisions, class_name: "Publishing::Info::App::EntryRevision",
                                      foreign_key: :restored_from_revision_id, inverse_of: :restored_from_revision,
                                      dependent: :restrict_with_exception
        has_many :promoted_versions, class_name: "Publishing::Info::App::EntryVersion",
                                     inverse_of: :entry_revision, dependent: :restrict_with_exception

        validates :sequence, uniqueness: { scope: :entry_id }, on: :create
        validates :created_by_operator_public_id, length: { maximum: 21 }
        # Unique indexes that include the primary key back composite references; checked only for an explicit id.
        validates :id, uniqueness: { scope: %i(entry_id) }, allow_nil: true, if: :will_save_change_to_id?
        validates :id, uniqueness: { scope: %i(locale) }, allow_nil: true, if: :will_save_change_to_id?
      end
    end
  end
end
