# frozen_string_literal: true

module Publishing
  module News
    module Com
      class VersionMultipleTaxonomyAssignment < PublishingRecord
        self.table_name = "publishing_news_com_version_multiple_taxonomy_assignments"
        include PublishingFamilyTaxonomyAssignment

        PublishingFamilyTaxonomyAssignment.configure(self)
        include PublishingTaxonomySnapshot

        PublishingTaxonomySnapshot.configure(self)

        validate :reject_user_supplied_position_snapshot, on: :create

        belongs_to :entry_version, class_name: "Publishing::News::Com::EntryVersion",
                                   inverse_of: :multiple_taxonomy_assignments
        validates :position,
                  numericality: { only_integer: true,
                                  greater_than_or_equal_to: 0,
                                  less_than_or_equal_to: 2_147_483_647, },
                  on: :create
        validates :term_path_snapshot, exclusion: { in: [nil] }

        scope :ordered, -> { order(:position) }

        validates :taxonomy_term_id, uniqueness: { scope: %i(entry_version_id vocabulary_id) }, on: :create
        validates :position, uniqueness: { scope: %i(entry_version_id vocabulary_id) }, on: :create

        def self.expected_kind = Publishing::TaxonomyKind::MULTIPLE_ORDERED_FLAT
        public_class_method :expected_kind
      end
    end
  end
end
