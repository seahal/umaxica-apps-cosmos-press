# frozen_string_literal: true

require "test_helper"

class OperatorChronicleHaltCorrelationConstraintsTest < ActiveSupport::TestCase
  setup do
    @attributes = {
      actor_type: "Operator",
      actor_id: 381,
      subject_type: "OrgNormalSignInTransaction",
      subject_id: 381,
      event_id: OperatorChronicleEvent::SIGN_FLOW_HALTED,
      level_id: OperatorChronicleLevel::NOTHING,
      occurred_at: Time.utc(2026, 11, 1),
    }
    @model_attributes = @attributes.except(:actor_type, :actor_id).merge(
      actor: OperatorChronicleLevel.find(OperatorChronicleLevel::NOTHING),
    )
    @context = { "transaction_public_id" => "transaction-a", "halt_generation" => "100" }
  end

  test "halt audit keys reject missing nonstring empty and Unicode blank values through bulk insertion" do
    contexts = [{}, @context.except("transaction_public_id"), @context.except("halt_generation"), [], false, 0, "event"]
    ["transaction_public_id", "halt_generation"].each do |key|
      [nil, false, 0, [], {}, "", " ",
       "\t\n\r\u0085\u00a0\u1680\u2000\u200a\u2028\u2029\u202f\u205f\u3000",].each do |value|
        contexts << @context.merge(key => value)
      end
    end
    contexts.each do |context|
      error =
        assert_raises(ActiveRecord::StatementInvalid) do
          OperatorChronicle.transaction(requires_new: true) do
            OperatorChronicle.insert_all!([@attributes.merge(context:)])
          end
        end

      assert_instance_of PG::CheckViolation, error.cause
      assert_equal "chk_operator_chronicles_sign_flow_halted_keys",
                   error.cause.result.error_field(PG::Result::PG_DIAG_CONSTRAINT_NAME)
    end
  end

  test "a SQL NULL context remains forbidden independently of halt correlation validation" do
    error =
      assert_raises(ActiveRecord::NotNullViolation) do
        OperatorChronicle.transaction(requires_new: true) do
          OperatorChronicle.insert_all!([@attributes.merge(context: nil)])
        end
      end

    assert_instance_of PG::NotNullViolation, error.cause
  end

  test "ordinary halt creation reports malformed context before attempting persistence" do
    [nil, [], {}, @context.merge("halt_generation" => false),
     @context.merge("halt_generation" => "\u3000"),].each do |context|
      audit = OperatorChronicle.new(@model_attributes.merge(context:))

      assert_not audit.valid?
      assert audit.errors.of_kind?(:context, :invalid)
      assert_raises(ActiveRecord::RecordInvalid) { audit.save! }
    end
  end

  test "ordinary duplicates preflight the exact halt tuple and independent keys remain writable" do
    original = OperatorChronicle.create!(@model_attributes.merge(context: @context))
    duplicate = OperatorChronicle.new(@model_attributes.merge(context: @context))

    assert_not duplicate.valid?
    assert duplicate.errors.of_kind?(:sign_flow_transaction_public_id, :taken)
    assert_raises(ActiveRecord::RecordInvalid) { duplicate.save! }
    assert_equal "transaction-a", original.reload.sign_flow_transaction_public_id
    assert_equal "100", original.sign_flow_halt_generation

    other_transaction = OperatorChronicle.create!(
      @model_attributes.merge(context: @context.merge("transaction_public_id" => "transaction-b")),
    )
    other_generation = OperatorChronicle.create!(
      @model_attributes.merge(context: @context.merge("halt_generation" => "101")),
    )

    assert_not_equal original.id, other_transaction.id
    assert_not_equal original.id, other_generation.id
  end

  test "halt generation remains an opaque nonblank string and other events keep independent contexts" do
    ["0", "-1", "generation-a", "\u200b", " padded "].each_with_index do |generation, index|
      context = { "transaction_public_id" => "transaction-#{index}", "halt_generation" => generation }
      record = OperatorChronicle.create!(@model_attributes.merge(context:))

      assert_equal context, record.reload.context
      assert_equal generation, record.sign_flow_halt_generation
    end
    [{}, @context, false].each do |context|
      2.times do
        record = OperatorChronicle.create!(
          @model_attributes.merge(event_id: OperatorChronicleEvent::LOGGED_IN, context:),
        )

        assert_equal context, record.reload.context
        assert_nil record.sign_flow_transaction_public_id
        assert_nil record.sign_flow_halt_generation
      end
    end
  end

  test "symbol-keyed Ruby context serializes to the same authoritative JSON correlation" do
    record = OperatorChronicle.create!(
      @model_attributes.merge(
        context: { transaction_public_id: "transaction-symbol",
                   halt_generation: "generation-symbol", },
      ),
    )

    assert_equal(
      { "transaction_public_id" => "transaction-symbol", "halt_generation" => "generation-symbol" },
      record.reload.context,
    )
    assert_equal "transaction-symbol", record.sign_flow_transaction_public_id
    assert_equal "generation-symbol", record.sign_flow_halt_generation
  end

  test "native generated fields derive from context and refuse explicit replacement" do
    OperatorChronicle.insert_all!([@attributes.merge(context: @context)])
    record = OperatorChronicle.find_by!(context: @context)

    assert_equal "transaction-a", record.sign_flow_transaction_public_id
    assert_equal "100", record.sign_flow_halt_generation
    error =
      assert_raises(ActiveRecord::StatementInvalid) do
        OperatorChronicle.transaction(requires_new: true) do
          OperatorChronicle.insert_all!(
            [
              @attributes.merge(
                context: @context.merge("halt_generation" => "101"),
                sign_flow_halt_generation: "forged",
              ),
            ],
          )
        end
      end

    assert_instance_of PG::GeneratedAlways, error.cause
    assert_equal 1, OperatorChronicle.where(context: @context).count
  end

  test "the halt correlation tuple remains unique under validation bypass" do
    attributes = @attributes.merge(context: @context)
    OperatorChronicle.insert_all!([attributes])
    error =
      assert_raises(ActiveRecord::RecordNotUnique) do
        OperatorChronicle.transaction(requires_new: true) { OperatorChronicle.insert_all!([attributes]) }
      end

    assert_instance_of PG::UniqueViolation, error.cause
    assert_equal "uniq_operator_chronicles_sign_flow_halted",
                 error.cause.result.error_field(PG::Result::PG_DIAG_CONSTRAINT_NAME)
  end
end
