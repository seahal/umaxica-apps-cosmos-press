# frozen_string_literal: true

require "test_helper"

class ClientChronicleUniquenessTest < ActiveSupport::TestCase
  test "new correlated Client audit records reject a duplicate canonical UUID before persistence" do
    actor = ClientChronicleLevel.find(ClientChronicleLevel::INFO)
    attributes = {
      actor: actor,
      subject_type: "Client",
      subject_id: "381",
      event_id: ClientChronicleEvent::LOGGED_IN,
      level_id: ClientChronicleLevel::NOTHING,
      occurred_at: Time.utc(2026, 11, 1),
      context: {},
      event_uuid: "aaaaaaaa-1111-4111-8111-111111111111",
    }
    original = ClientChronicle.create!(attributes)
    duplicate = ClientChronicle.new(attributes.merge(event_uuid: attributes.fetch(:event_uuid).upcase))

    assert_not duplicate.valid?
    assert duplicate.errors.of_kind?(:event_uuid, :taken)
    assert_raises(ActiveRecord::RecordInvalid) { duplicate.save! }
    assert_equal 1, ClientChronicle.where(event_uuid: attributes.fetch(:event_uuid)).count
    assert_equal original.id, ClientChronicle.find_by!(event_uuid: attributes.fetch(:event_uuid)).id

    independent = ClientChronicle.create!(attributes.merge(event_uuid: "bbbbbbbb-1111-4111-8111-111111111111"))

    assert_not_equal original.id, independent.id
  end

  test "uncorrelated Client audit records retain independent nullable UUIDs" do
    actor = ClientChronicleLevel.find(ClientChronicleLevel::INFO)
    attributes = {
      actor: actor,
      subject_type: "Client",
      subject_id: "381",
      event_id: ClientChronicleEvent::LOGGED_IN,
      level_id: ClientChronicleLevel::NOTHING,
      occurred_at: Time.utc(2026, 11, 1),
      context: {},
      event_uuid: nil,
    }
    first = ClientChronicle.create!(attributes)
    second = ClientChronicle.create!(attributes)

    assert_nil first.reload.event_uuid
    assert_nil second.reload.event_uuid
    assert_not_equal first.id, second.id
  end

  test "bulk insertion retains native Client audit UUID uniqueness independently of validation" do
    actor = ClientChronicleLevel.find(ClientChronicleLevel::INFO)
    original = ClientChronicle.create!(
      actor: actor, subject_type: "Client", subject_id: "381",
      event_id: ClientChronicleEvent::LOGGED_IN, level_id: ClientChronicleLevel::NOTHING,
      occurred_at: Time.utc(2026, 11, 1), context: {},
      event_uuid: "cccccccc-1111-4111-8111-111111111111",
    )
    error =
      assert_raises(ActiveRecord::RecordNotUnique) do
        ClientChronicle.transaction(requires_new: true) do
          ClientChronicle.insert_all!([original.attributes.except("id")])
        end
      end

    assert_instance_of PG::UniqueViolation, error.cause
    assert_equal "index_client_chronicles_on_event_uuid",
                 error.cause.result.error_field(PG::Result::PG_DIAG_CONSTRAINT_NAME)
    assert_equal 1, ClientChronicle.where(event_uuid: original.event_uuid).count
  end
  test "supplied malformed UUIDs cannot silently become uncorrelated nil values" do
    actor = ClientChronicleLevel.find(ClientChronicleLevel::INFO)
    ["", " ", "\u3000", "not-a-uuid", "aaaaaaaa-1111-4111-8111", false, 0, [], {}].each do |value|
      record = ClientChronicle.new(
        actor:, subject_type: "Client", subject_id: "381",
        event_id: ClientChronicleEvent::LOGGED_IN, level_id: ClientChronicleLevel::NOTHING,
        occurred_at: Time.utc(2026, 11, 1), context: {}, event_uuid: value,
      )

      assert_not record.valid?, "invalid supplied UUID #{value.inspect} must not become an uncorrelated event"
      assert record.errors.of_kind?(:event_uuid, :invalid)
      assert_raises(ActiveRecord::RecordInvalid) { record.save! }
    end
  end

  test "PostgreSQL independently refuses malformed UUID text" do
    connection = ClientChronicle.lease_connection
    error =
      assert_raises(ActiveRecord::StatementInvalid) do
        ClientChronicle.transaction(requires_new: true) do
          connection.execute(<<~SQL.squish)
            INSERT INTO client_chronicles
              (actor_id, actor_type, subject_id, subject_type, event_id, level_id, occurred_at, event_uuid, created_at, updated_at)
            VALUES (381, 'Client', '381', 'Client', 3, 4, clock_timestamp(), 'malformed-uuid', clock_timestamp(), clock_timestamp())
          SQL
        end
      end

    assert_instance_of PG::InvalidTextRepresentation, error.cause
  end

  test "current PostgreSQL UUID cast variants retain their canonical nonsecret correlation identity" do
    canonical = "dddddddd-1111-4111-8111-111111111111"
    variants = [canonical, canonical.upcase, canonical.delete("-"), "{#{canonical}}",
                canonical.delete("-").scan(/.{4}/).join("-"),]
    variants.each do |value|
      record = ClientChronicle.new(
        actor: ClientChronicleLevel.find(ClientChronicleLevel::INFO), subject_type: "Client", subject_id: "381",
        event_id: ClientChronicleEvent::LOGGED_IN, level_id: ClientChronicleLevel::NOTHING,
        occurred_at: Time.utc(2026, 11, 1), context: {}, event_uuid: value,
      )

      assert_predicate record, :valid?
      assert_equal canonical, record.event_uuid
    end
  end
end
