# frozen_string_literal: true

module Publishing
  module Info
    module Com
      class TaxonomyTerm < PublishingRecord
        self.table_name = "publishing_info_com_taxonomy_terms"
        include PublishingTaxonomyTermRecord

        has_many :revision_single_taxonomy_assignments,
                 class_name: "Publishing::Info::Com::RevisionSingleTaxonomyAssignment",
                 inverse_of: :taxonomy_term, dependent: :restrict_with_exception
        has_many :revision_multiple_taxonomy_assignments,
                 class_name: "Publishing::Info::Com::RevisionMultipleTaxonomyAssignment",
                 inverse_of: :taxonomy_term, dependent: :restrict_with_exception
        has_many :version_single_taxonomy_assignments,
                 class_name: "Publishing::Info::Com::VersionSingleTaxonomyAssignment",
                 inverse_of: :taxonomy_term, dependent: :restrict_with_exception
        has_many :version_multiple_taxonomy_assignments,
                 class_name: "Publishing::Info::Com::VersionMultipleTaxonomyAssignment",
                 inverse_of: :taxonomy_term, dependent: :restrict_with_exception

        validates :slug, :vocabulary_kind, exclusion: { in: [nil] }
        # Unique indexes that include the primary key back composite references; checked only for an explicit id.
        validates :id, uniqueness: { scope: %i(vocabulary_id locale) }, allow_nil: true, if: :will_save_change_to_id?
      end
    end
  end
end
