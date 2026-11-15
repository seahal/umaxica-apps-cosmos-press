# frozen_string_literal: true

module Publishing
  module Info
    module App
      class RevisionSingleTaxonomyAssignment < PublishingRecord
        self.table_name = "publishing_info_app_revision_single_taxonomy_assignments"
        include PublishingFamilyTaxonomyAssignment

        PublishingFamilyTaxonomyAssignment.configure(self)

        belongs_to :entry_revision, class_name: "Publishing::Info::App::EntryRevision",
                                    inverse_of: :single_taxonomy_assignments

        validates :vocabulary_id, uniqueness: { scope: :entry_revision_id }

        def self.expected_kind = Publishing::TaxonomyKind::SINGLE_HIERARCHICAL
        public_class_method :expected_kind
      end
    end
  end
end
