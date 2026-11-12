# typed: false
# frozen_string_literal: true

# Physical deletion remains limited to the previously retained Chronicle families and their
# database-owned purge eligibility. Source-domain account and credential cleanup belongs outside Press.
class RetentionPurgeJob < ApplicationJob
  queue_as :retention

  DEFAULT_BATCH_SIZE = 500
  MAX_BATCH_SIZE = 500
  RETAINABLE_MODELS = [
    AppPreferenceChronicle,
    OrgPreferenceChronicle,
    ClientChronicle,
    OperatorChronicle,
  ].freeze
  FEATURE_NAME = :retention_purge_suspended

  public

  def perform(batch_size: DEFAULT_BATCH_SIZE)
    limit = normalized_batch_size(batch_size)
    unless limit&.between?(1, MAX_BATCH_SIZE)
      raise ArgumentError, "batch_size must be between 1 and #{MAX_BATCH_SIZE}"
    end

    if FeatureFlags.enabled?(FEATURE_NAME)
      Rails.logger.warn(JitLogEvent.format("retention.purge.suspended"))
      return
    end

    failures = []
    ChronicleRecord.connected_to(role: :writing) do
      RETAINABLE_MODELS.each do |model|
        now = model.database_now
        # The accepted retention boundary authorizes set-based purge after the stored deadline;
        # audit records are never cascaded from a removed principal or preference database.
        model.where(purge_eligible_at: ..now).in_batches(of: limit).delete_all
      rescue ActiveRecord::ActiveRecordError => e
        failures << e
        Rails.error.report(
          e, handled: false,
             context: { job: self.class.name, retained_model: model.name, batch_size: limit },
        )
      end
    end
    raise failures.first if failures.any?
  end

  private

  def normalized_batch_size(value)
    return value if value.is_a?(Integer)
    return Integer(value) if value.is_a?(String)

    nil
  rescue ArgumentError, TypeError
    nil
  end
end
