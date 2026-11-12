# frozen_string_literal: true

module Publishing
  module News
    module App
      class VersionSingleTaxonomyAssignment < PublishingRecord
        self.table_name = "publishing_news_app_version_single_taxonomy_assignments"
        include PublishingFamilyTaxonomyAssignment
        include PublishingTaxonomySnapshot

        belongs_to :entry_version, class_name: "Publishing::News::App::EntryVersion",
                                   inverse_of: :single_taxonomy_assignments

        validates :term_path_snapshot, exclusion: { in: [nil] }

        validates :vocabulary_id, uniqueness: { scope: :entry_version_id }, on: :create

        def self.expected_kind = Publishing::TaxonomyKind::SINGLE_HIERARCHICAL
      end
    end
  end
end
