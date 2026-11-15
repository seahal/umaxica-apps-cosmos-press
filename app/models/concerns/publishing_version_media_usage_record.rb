# frozen_string_literal: true

module PublishingVersionMediaUsageRecord
  extend ActiveSupport::Concern

  class << self
    public

    def configure(model_class)
      model_class.include(PublicId)
      PublicId.configure(model_class)

      model_class.class_eval do
        before_update { raise(ActiveRecord::ReadOnlyRecord, "#{self.class.name} is immutable") }
        before_destroy { raise(ActiveRecord::ReadOnlyRecord, "#{self.class.name} is immutable") }

        family = name.deconstantize
        belongs_to :media_file, class_name: "Publishing::MediaFile"
        belongs_to :entry_version, class_name: "#{family}::EntryVersion", inverse_of: :media_usages

        validates :role, presence: true
        validates :position,
                  numericality: { greater_than_or_equal_to: 0,
                                  less_than_or_equal_to: 2_147_483_647,
                                  only_integer: true, }
        validates :position, uniqueness: { scope: %i(entry_version_id role field_path block_path) }, on: :create
      end
    end
  end
end
