# frozen_string_literal: true

class EnforceOperatorHaltCorrelation < ActiveRecord::Migration[8.2]
  INDEX_NAME = "uniq_operator_chronicles_sign_flow_halted"
  CHECK_NAME = "chk_operator_chronicles_sign_flow_halted_keys"
  OLD_EXPRESSIONS = "(context->>'transaction_public_id'), (context->>'halt_generation')"
  OLD_CHECK = "event_id <> 18 OR (context ? 'transaction_public_id' AND context ? 'halt_generation')"
  VALID_CORRELATION = <<~'SQL'.squish
    jsonb_typeof(context) = 'object'
    AND context ? 'transaction_public_id' AND context ? 'halt_generation'
    AND jsonb_typeof(context->'transaction_public_id') = 'string'
    AND jsonb_typeof(context->'halt_generation') = 'string'
    AND (context->>'transaction_public_id') ~ U&'[^\0009-\000D\0020\0085\00A0\1680\2000-\200A\2028\2029\202F\205F\3000]'
    AND (context->>'halt_generation') ~ U&'[^\0009-\000D\0020\0085\00A0\1680\2000-\200A\2028\2029\202F\205F\3000]'
  SQL

  def up
    invalid_count = select_value(<<~SQL.squish).to_i
      SELECT count(*) FROM operator_chronicles WHERE event_id = 18 AND (#{VALID_CORRELATION}) IS NOT TRUE
    SQL
    if invalid_count.positive?
      raise ActiveRecord::MigrationError,
            "operator halt audit has #{invalid_count} invalid correlation contexts; repair authoritative data before retrying"
    end

    # Generated projections preserve JSON as authority. Adding stored columns rewrites the table;
    # production requires a table-size and maintenance-window assessment before deployment.
    safety_assured do
      add_column(
        :operator_chronicles, :sign_flow_transaction_public_id, :virtual,
        type: :text,
        as: "CASE WHEN event_id = 18 THEN context->>'transaction_public_id' END",
        stored: true,
      )
      add_column(
        :operator_chronicles, :sign_flow_halt_generation, :virtual,
        type: :text,
        as: "CASE WHEN event_id = 18 THEN context->>'halt_generation' END",
        stored: true,
      )
      remove_check_constraint(:operator_chronicles, name: CHECK_NAME)
      add_check_constraint(:operator_chronicles, "event_id <> 18 OR ((#{VALID_CORRELATION}) IS TRUE)", name: CHECK_NAME)
      add_index(
        :operator_chronicles, %i(sign_flow_transaction_public_id sign_flow_halt_generation),
        unique: true, where: "event_id = 18", name: "#{INDEX_NAME}_new",
      )
      remove_index(:operator_chronicles, name: INDEX_NAME)
      rename_index(:operator_chronicles, "#{INDEX_NAME}_new", INDEX_NAME)
    end
  end

  def down
    safety_assured do
      add_index(
        :operator_chronicles, OLD_EXPRESSIONS, unique: true, where: "event_id = 18", name: "#{INDEX_NAME}_old",
      )
      remove_index(:operator_chronicles, name: INDEX_NAME)
      rename_index(:operator_chronicles, "#{INDEX_NAME}_old", INDEX_NAME)
      remove_check_constraint(:operator_chronicles, name: CHECK_NAME)
      add_check_constraint(:operator_chronicles, OLD_CHECK, name: CHECK_NAME)
      remove_column(:operator_chronicles, :sign_flow_halt_generation, :virtual)
      remove_column(:operator_chronicles, :sign_flow_transaction_public_id, :virtual)
    end
  end
end
