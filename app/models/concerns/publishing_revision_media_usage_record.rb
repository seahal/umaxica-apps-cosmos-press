# frozen_string_literal: true

module PublishingRevisionMediaUsageRecord
  extend ActiveSupport::Concern

  # FIXME: Violates Umaxica/NoConcernInclusionHooks; move the declarations in this block into each class that includes this concern.
  included do
    include PublicId

    family = name.deconstantize
    belongs_to :media_file, class_name: "Publishing::MediaFile"
    belongs_to :entry_revision, class_name: "#{family}::EntryRevision", inverse_of: :media_usages

    validates :role, presence: true
    validates :position,
              numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 2_147_483_647, only_integer: true }
    validates :position, uniqueness: { scope: %i(entry_revision_id role field_path block_path) }
    validate :path_present
  end

  private

  def path_present
    return if field_path.present? || block_path.present?

    errors.add(:base, "must have a field_path or block_path")
  end
end
