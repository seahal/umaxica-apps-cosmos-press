# frozen_string_literal: true

module PublishingRevisionMediaUsageRecord
  extend ActiveSupport::Concern

  class << self
    public

    def configure(model_class)
      model_class.include(PublicId)
      PublicId.configure(model_class)

      model_class.class_eval do
        family = name.deconstantize
        belongs_to :media_file, class_name: "Publishing::MediaFile"
        belongs_to :entry_revision, class_name: "#{family}::EntryRevision", inverse_of: :media_usages

        validates :role, presence: true
        validates :position,
                  numericality: { greater_than_or_equal_to: 0,
                                  less_than_or_equal_to: 2_147_483_647,
                                  only_integer: true, }
        validates :position, uniqueness: { scope: %i(entry_revision_id role field_path block_path) }
        validate :path_present
      end
    end
  end

  private

  def path_present
    return if field_path.present? || block_path.present?

    errors.add(:base, "must have a field_path or block_path")
  end
end
