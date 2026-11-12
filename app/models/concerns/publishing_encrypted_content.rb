# frozen_string_literal: true

# Non-deterministic Active Record Encryption for revision/version title,
# summary, and structured body. PostgreSQL stores ciphertext text; Ruby sees
# String title/summary and a Hash body.
module PublishingEncryptedContent
  extend ActiveSupport::Concern

  BODY_SHAPE_ERROR = "must be a JSON object"

  # FIXME: Violates Umaxica/NoConcernInclusionHooks; move the declarations in this block into each class that includes this concern.
  included do
    serialize :body, coder: JSON
    encrypts :title, :summary, :body

    # SQL requires a value but permits blank locale strings; preserve that distinction.
    validates :locale, exclusion: { in: [nil], message: :blank }, on: :create

    # Creation checks preserve immutable version and promoted-revision update guards.
    validates :content_digest, length: { is: 64 }, format: { with: /\A[0-9a-f]+\z/ }, on: :create

    validates :title, presence: true
    validates :schema_version,
              numericality: { greater_than: 0, less_than_or_equal_to: 2_147_483_647, only_integer: true }
    # Rails exclusion checks array elements; only scalar nil belongs to this requiredness check.
    validates :body, exclusion: { in: [nil], message: BODY_SHAPE_ERROR }, if: -> { body.nil? }
    validate :body_must_be_json_object
  end

  private

  def body_must_be_json_object
    return if body.nil? || body.is_a?(Hash)

    errors.add(:body, BODY_SHAPE_ERROR)
  end
end
