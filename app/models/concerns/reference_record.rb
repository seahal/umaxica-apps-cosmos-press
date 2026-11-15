# typed: false
# frozen_string_literal: true

module ReferenceRecord
  extend ActiveSupport::Concern

  class << self
    public

    def configure(model_class)
      model_class.record_timestamps = false
    end
  end

  class_methods do
    def nothing_id
      self::NOTHING
    end

    def ensure_defaults!
      insert_missing_fixed_ids!(self::DEFAULTS)
    end
  end
end
