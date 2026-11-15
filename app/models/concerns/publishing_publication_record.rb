# frozen_string_literal: true

module PublishingPublicationRecord
  extend ActiveSupport::Concern

  class << self
    public

    def configure(model_class)
      model_class.include(PublicId)
      PublicId.configure(model_class)

      model_class.class_eval do
        # Keep required creation input distinct from unloaded attributes on projected existing rows.
        validates :effective_from, exclusion: { in: [nil], message: :blank }, on: :create,
                                   if: -> { effective_from.nil? }
        validate :effective_from_must_be_timestamp, on: :create

        family = name.deconstantize
        belongs_to :entry, class_name: "#{family}::Entry", inverse_of: :publications
        belongs_to :entry_version, class_name: "#{family}::EntryVersion", inverse_of: :publications

        scope :active, -> {
          now = Time.current
          where(cancelled_at: nil)
            .where(effective_from: ..now)
            .where("effective_until IS NULL OR effective_until > ?", now)
        }
      end
    end
  end
  public

  def cancelled? = cancelled_at.present?

  def terminated? = terminated_at.present?

  private

  def effective_from_must_be_timestamp
    value = effective_from
    return if value.nil? || value.is_a?(Time) || value.is_a?(Date)
    return if value.is_a?(Float) && value.infinite?

    errors.add(:effective_from, value.blank? ? :blank : :invalid)
  end
end
