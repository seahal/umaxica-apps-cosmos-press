# frozen_string_literal: true

module PublishingEntryVersionRecord
  extend ActiveSupport::Concern

  class << self
    public

    def configure(model_class)
      model_class.include(PublicId)
      PublicId.configure(model_class)
      model_class.include(PublishingEncryptedContent)
      PublishingEncryptedContent.configure(model_class)

      model_class.class_eval do
        # Keep immutable updates on their existing ReadOnlyRecord boundary.
        validates :sequence,
                  numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 2_147_483_647 },
                  on: :create

        before_update { raise(ActiveRecord::ReadOnlyRecord, "#{self.class.name} is immutable") }
        before_destroy { raise(ActiveRecord::ReadOnlyRecord, "#{self.class.name} is immutable") }

        family = name.deconstantize
        belongs_to :entry, class_name: "#{family}::Entry", inverse_of: :versions
        belongs_to :entry_revision, class_name: "#{family}::EntryRevision"
        has_many :publications, class_name: "#{family}::Publication", inverse_of: :entry_version,
                                dependent: :restrict_with_exception
        has_many :media_usages, class_name: "#{family}::VersionMediaUsage", inverse_of: :entry_version,
                                dependent: :restrict_with_exception
        has_many :single_taxonomy_assignments, class_name: "#{family}::VersionSingleTaxonomyAssignment",
                                               inverse_of: :entry_version, dependent: :restrict_with_exception
        has_many :multiple_taxonomy_assignments, -> { ordered },
                 class_name: "#{family}::VersionMultipleTaxonomyAssignment",
                 inverse_of: :entry_version, dependent: :restrict_with_exception
      end
    end
  end
end
