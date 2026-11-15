# frozen_string_literal: true

module PublishingEntrySlugRecord
  extend ActiveSupport::Concern

  STATES = %w(reserved canonical redirect).freeze

  class << self
    public

    def configure(model_class)
      model_class.include(PublicId)
      PublicId.configure(model_class)

      model_class.class_eval do
        # SQL requires a value but permits blank locale strings; preserve that distinction.
        validates :locale, exclusion: { in: [nil], message: :blank }, on: :create

        family = name.deconstantize
        belongs_to :entry, class_name: "#{family}::Entry", inverse_of: :slugs
        validates :state, inclusion: { in: STATES }
        scope :canonical, -> { where(state: "canonical") }
      end
    end
  end
end
