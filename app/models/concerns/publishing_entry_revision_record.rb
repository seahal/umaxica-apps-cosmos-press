# frozen_string_literal: true

module PublishingEntryRevisionRecord
  extend ActiveSupport::Concern

  class << self
    public

    def configure(model_class)
      model_class.include(PublicId)
      PublicId.configure(model_class)
      model_class.include(PublishingEncryptedContent)
      PublishingEncryptedContent.configure(model_class)

      model_class.class_eval do
        validates :sequence,
                  numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 2_147_483_647 }

        family = name.deconstantize
        belongs_to :entry, class_name: "#{family}::Entry", inverse_of: :revisions
        belongs_to :restored_from_revision, class_name: "#{family}::EntryRevision", optional: true
        belongs_to :restored_from_version, class_name: "#{family}::EntryVersion", optional: true
        has_many :media_usages, class_name: "#{family}::RevisionMediaUsage", inverse_of: :entry_revision,
                                dependent: :restrict_with_exception
        has_many :single_taxonomy_assignments, class_name: "#{family}::RevisionSingleTaxonomyAssignment",
                                               inverse_of: :entry_revision, dependent: :destroy
        has_many :multiple_taxonomy_assignments, -> { ordered },
                 class_name: "#{family}::RevisionMultipleTaxonomyAssignment",
                 inverse_of: :entry_revision, dependent: :destroy
      end
    end
  end
  public

  def archived_taxonomy_assignments
    taxonomy_assignments.select do |assignment|
      assignment.vocabulary.archived? || assignment.taxonomy_term.archived_in_path.any?
    end
  end

  def promoted?
    entry.versions.exists?(entry_revision_id: id)
  end

  def taxonomy_assignments
    association_scope(:single_taxonomy_assignments).includes(:vocabulary, :taxonomy_term).to_a +
      association_scope(:multiple_taxonomy_assignments).includes(:vocabulary, :taxonomy_term).to_a
  end

  private

  def association_scope(name)
    association(name).scope
  end
end
