# typed: false
# frozen_string_literal: true

require "test_helper"

class ModelOnlyLineCoverageTest < ActiveSupport::TestCase
  test "actor configuration null values and dynamic access preserve value semantics" do
    null_value = Actor::Configuration::NULL_VALUE
    configuration = Actor::Configuration.new(feature: "enabled")
    same = Actor::Configuration.new(feature: "enabled")

    assert_withheld { null_value.nil? }
    assert_equal null_value, Actor::Configuration::NullValue.new
    assert_respond_to null_value, :anything
    assert_same null_value, null_value.anything.deeply.missing
    assert_equal "enabled", configuration[:feature]
    assert_equal "enabled", configuration.feature
    assert_respond_to configuration, :feature
    assert_equal configuration, same
    assert_equal configuration.hash, same.hash
  end

  test "retainable discard now validates duration and clamps to persisted creation" do
    record = AppPreferenceChronicle.new(created_at: 1.minute.from_now)

    assert_raises(ArgumentError) { record.discard_now!(purge_after: 10) }

    updates = []
    record.stub(:update!, ->(attributes) { updates << attributes }) do
      now = Time.current
      record.discard_now!(purge_after: 1.day, now: now)
    end

    assert_equal record.created_at, updates.last[:discard_at]
    assert_operator updates.last[:purge_eligible_at], :>, updates.last[:discard_at]
  end

  test "small public model APIs and reference defaults are covered by model tests" do
    AppPreferenceChronicleEvent.ensure_defaults!
    ComPreferenceChronicleEvent.ensure_defaults!
    OrgPreferenceChronicleEvent.ensure_defaults!

    assert_predicate AppPreferenceChronicleEvent.where(id: AppPreferenceChronicleEvent::DEFAULTS), :exists?
    assert_predicate ComPreferenceChronicleEvent.where(id: ComPreferenceChronicleEvent::DEFAULTS), :exists?
    assert_predicate OrgPreferenceChronicleEvent.where(id: OrgPreferenceChronicleEvent::DEFAULTS), :exists?
  end

  test "org preference chronicle cannot fabricate a missing authority actor" do
    chronicle = OrgPreferenceChronicle.new(subject_id: 123, subject_type: "OrgPreference")

    assert_raises(GovernanceUnavailableError) { chronicle.default_actor_to_preference }
    assert_equal 123, chronicle.subject_id
    assert_equal "OrgPreference", chronicle.subject_type
  end
end
