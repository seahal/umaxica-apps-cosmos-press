# frozen_string_literal: true

module Publishing
  module News
    module Org
      class RevisionMultipleTaxonomyAssignment < PublishingRecord
        self.table_name = "publishing_news_org_revision_multiple_taxonomy_assignments"
        include PublishingFamilyTaxonomyAssignment

        PublishingFamilyTaxonomyAssignment.configure(self)

        belongs_to :entry_revision, class_name: "Publishing::News::Org::EntryRevision",
                                    inverse_of: :multiple_taxonomy_assignments
        validates :position,
                  numericality: { only_integer: true,
                                  greater_than_or_equal_to: 0,
                                  less_than_or_equal_to: 2_147_483_647, }

        scope :ordered, -> { order(:position) }

        validates :taxonomy_term_id, uniqueness: { scope: %i(entry_revision_id vocabulary_id) }
        validates :position, uniqueness: { scope: %i(entry_revision_id vocabulary_id) }

        def self.expected_kind = Publishing::TaxonomyKind::MULTIPLE_ORDERED_FLAT
        public_class_method :expected_kind
      end
    end
  end
end
