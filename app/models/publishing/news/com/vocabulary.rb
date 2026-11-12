# frozen_string_literal: true

module Publishing
  module News
    module Com
      class Vocabulary < PublishingRecord
        self.table_name = "publishing_news_com_vocabularies"
        include PublishingVocabularyRecord

        has_many :revision_single_taxonomy_assignments,
                 class_name: "Publishing::News::Com::RevisionSingleTaxonomyAssignment",
                 inverse_of: :vocabulary, dependent: :restrict_with_exception
        has_many :revision_multiple_taxonomy_assignments,
                 class_name: "Publishing::News::Com::RevisionMultipleTaxonomyAssignment",
                 inverse_of: :vocabulary, dependent: :restrict_with_exception
        has_many :version_single_taxonomy_assignments,
                 class_name: "Publishing::News::Com::VersionSingleTaxonomyAssignment",
                 inverse_of: :vocabulary, dependent: :restrict_with_exception
        has_many :version_multiple_taxonomy_assignments,
                 class_name: "Publishing::News::Com::VersionMultipleTaxonomyAssignment",
                 inverse_of: :vocabulary, dependent: :restrict_with_exception

        validates :key, exclusion: { in: [nil] }
        # Unique indexes that include the primary key back composite references; checked only for an explicit id.
        validates :id, uniqueness: { scope: %i(kind) }, allow_nil: true, if: :will_save_change_to_id?
      end
    end
  end
end
