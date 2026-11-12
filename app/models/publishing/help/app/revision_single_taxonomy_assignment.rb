# frozen_string_literal: true

module Publishing
  module Help
    module App
      class RevisionSingleTaxonomyAssignment < PublishingRecord
        self.table_name = "publishing_help_app_revision_single_taxonomy_assignments"
        include PublishingFamilyTaxonomyAssignment

        belongs_to :entry_revision, class_name: "Publishing::Help::App::EntryRevision",
                                    inverse_of: :single_taxonomy_assignments

        validates :vocabulary_id, uniqueness: { scope: :entry_revision_id }

        def self.expected_kind = Publishing::TaxonomyKind::SINGLE_HIERARCHICAL
      end
    end
  end
end
