# frozen_string_literal: true

# Non-deterministic Active Record Encryption for revision/version title,
# summary, and structured body. PostgreSQL stores ciphertext text; Ruby sees
# String title/summary and a Hash body.
module PublishingEncryptedContent
  extend ActiveSupport::Concern

  BODY_SHAPE_ERROR = "must be a JSON object"

  class << self
    public

    def configure(model_class)
      model_class.serialize(:body, coder: JSON)
      model_class.encrypts(:title, :summary, :body)

      # SQL requires a value but permits blank locale strings; preserve that distinction.
      model_class.validates :locale, exclusion: { in: [nil], message: :blank }, on: :create

      # PostgreSQL enforces the same SHA-256 shape for direct inserts and updates.
      model_class.validates :content_digest, presence: true
      model_class.validates :content_digest, length: { is: 64 }, format: { with: /\A[0-9a-f]+\z/ }

      model_class.validates :title, presence: true
      model_class.validates :schema_version,
                            numericality: { greater_than: 0, less_than_or_equal_to: 2_147_483_647, only_integer: true }
      # Rails exclusion checks array elements; only scalar nil belongs to this requiredness check.
      model_class.validates :body, exclusion: { in: [nil], message: BODY_SHAPE_ERROR }, if: -> { body.nil? }
      model_class.validate :body_must_be_json_object
    end
  end

  private

  def body_must_be_json_object
    return if body.nil? || body.is_a?(Hash)

    errors.add(:body, BODY_SHAPE_ERROR)
  end
end
