# frozen_string_literal: true

require "test_helper"

class ChronicleGovernanceDependencyTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "client and operator historical references remain readable without governance records" do
    client_audit = ClientChronicle.new(subject_type: "Client", subject_id: "381")
    operator_audit = OperatorChronicle.new(subject_type: "Operator", subject_id: 479)

    assert_equal "381", client_audit.user_id
    assert_equal 479, operator_audit.subject_id
    assert_raises(GovernanceUnavailableError) { client_audit.user }
    assert_raises(GovernanceUnavailableError) { client_audit.user = Object.new }
    assert_raises(GovernanceUnavailableError) { operator_audit.staff }
    assert_raises(GovernanceUnavailableError) { operator_audit.staff = Object.new }
    assert_equal "381", client_audit.subject_id
    assert_equal 479, operator_audit.subject_id
  end

  test "preference helper reads and assignments explicitly refuse unavailable authority" do
    [AppPreferenceChronicle, ComPreferenceChronicle, OrgPreferenceChronicle].each do |model|
      audit = model.new(subject_id: 381, subject_type: "HistoricalPreference")

      assert_raises(GovernanceUnavailableError) { audit.app_preference } if model == AppPreferenceChronicle
      assert_raises(GovernanceUnavailableError) { audit.com_preference } if model == ComPreferenceChronicle
      assert_raises(GovernanceUnavailableError) { audit.org_preference } if model == OrgPreferenceChronicle

      assert_equal 381, audit.subject_id
      assert_equal "HistoricalPreference", audit.subject_type
    end

    app_audit = AppPreferenceChronicle.new(subject_id: 381, subject_type: "AppPreference")
    com_audit = ComPreferenceChronicle.new(subject_id: 381, subject_type: "ComPreference")
    org_audit = OrgPreferenceChronicle.new(subject_id: 381, subject_type: "OrgPreference")

    assert_raises(GovernanceUnavailableError) { app_audit.app_preference = Object.new }
    assert_raises(GovernanceUnavailableError) { com_audit.com_preference = Object.new }
    assert_raises(GovernanceUnavailableError) { org_audit.org_preference = Object.new }
    assert_equal "AppPreference", app_audit.subject_type
    assert_equal "ComPreference", com_audit.subject_type
    assert_equal "OrgPreference", org_audit.subject_type
  end
  test "missing historical polymorphic actor authority raises with the original cause" do
    [ClientChronicle, OperatorChronicle, Chronicle, ComPreferenceChronicle, OrgPreferenceChronicle].each do |model|
      audit = model.new(actor_id: 381, actor_type: "RemovedHistoricalActor")
      error = assert_raises(DependencyUnavailableError) { audit.actor }

      assert_kind_of NameError, error.cause
      assert_equal 381, audit.actor_id
      assert_equal "RemovedHistoricalActor", audit.actor_type
    end
  end

  test "missing historical subject authority raises without rewriting the scalar reference" do
    audit = Chronicle.new(subject_id: 381, subject_type: "RemovedHistoricalSubject")
    error = assert_raises(DependencyUnavailableError) { audit.subject }

    assert_kind_of NameError, error.cause
    assert_equal 381, audit.subject_id
  end

  test "optional polymorphic references remain absent when no reference was recorded" do
    audit = Chronicle.new

    assert_nil audit.actor
    assert_nil audit.subject
  end

  test "kept local polymorphic actor records still resolve" do
    actor = ClientChronicleLevel.find(ClientChronicleLevel::INFO)
    audit = ClientChronicle.new(actor: actor)

    assert_equal actor, audit.actor
  end
end
