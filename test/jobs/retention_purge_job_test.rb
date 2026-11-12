# frozen_string_literal: true

require "test_helper"

class RetentionPurgeJobTest < ActiveJob::TestCase
  fixtures :app_preference_chronicles, :com_preference_chronicles

  teardown { Flipper.disable(RetentionPurgeJob::FEATURE_NAME) }

  test "rejects a retention batch size outside the bounded execution range" do
    error =
      assert_raises(ArgumentError) do
        RetentionPurgeJob.perform_now(batch_size: 501)
      end

    assert_equal "batch_size must be between 1 and 500", error.message
  end

  test "rejects fractional retention batch sizes instead of truncating them" do
    error =
      assert_raises(ArgumentError) do
        RetentionPurgeJob.perform_now(batch_size: 1.5)
      end

    assert_equal "batch_size must be between 1 and 500", error.message
  end

  test "rejects zero negative and missing retention batch sizes" do
    [0, -1, nil].each do |batch_size|
      error =
        assert_raises(ArgumentError) do
          RetentionPurgeJob.perform_now(batch_size: batch_size)
        end

      assert_equal "batch_size must be between 1 and 500", error.message
    end
  end

  test "accepts both inclusive retention batch-size boundaries before work" do
    FeatureFlags.stub(:enabled?, true) do
      [1, 500].each do |batch_size|
        assert_nothing_raised { RetentionPurgeJob.perform_now(batch_size:) }
      end
    end
  end

  test "accepts an integral string batch size through the public job interface" do
    FeatureFlags.stub(:enabled?, true) do
      # The validation is exercised before any destructive work is reached. The kill-switch stub
      # keeps this boundary test independent of retention rows while still using the public job
      # entrypoint.
      assert_nothing_raised { RetentionPurgeJob.perform_now(batch_size: "1") }
    end
  end

  test "only the four retained purge families are registered" do
    assert_equal [AppPreferenceChronicle, OrgPreferenceChronicle, ClientChronicle, OperatorChronicle],
                 RetentionPurgeJob::RETAINABLE_MODELS
  end

  test "a suspended purge preserves due audit history and the next run catches up" do
    audit = app_preference_chronicles(:one)
    AppPreferenceChronicle.where(id: audit.id).update_all(
      created_at: 3.days.ago, discard_at: 2.days.ago, purge_eligible_at: 1.day.ago,
    )
    Flipper.enable(RetentionPurgeJob::FEATURE_NAME)

    RetentionPurgeJob.perform_now

    assert AppPreferenceChronicle.exists?(audit.id)

    Flipper.disable(RetentionPurgeJob::FEATURE_NAME)
    RetentionPurgeJob.perform_now

    assert_not AppPreferenceChronicle.exists?(audit.id)
    assert_nothing_raised { RetentionPurgeJob.perform_now }
  end

  test "future audit deadlines and COM audit history remain preserved" do
    app_audit = app_preference_chronicles(:one)
    com_audit = com_preference_chronicles(:one)
    ComPreferenceChronicle.where(id: com_audit.id).update_all(
      created_at: 3.days.ago, discard_at: 2.days.ago, purge_eligible_at: 1.day.ago,
    )

    RetentionPurgeJob.perform_now

    assert AppPreferenceChronicle.exists?(app_audit.id)
    assert ComPreferenceChronicle.exists?(com_audit.id)
  end
  test "one database failure is reported and re-raised after later audit families are processed" do
    failure = ActiveRecord::StatementInvalid.new("retention database unavailable")
    reported = []
    later_family_processed = false
    now = Time.current

    AppPreferenceChronicle.stub(:where, ->(*) { raise failure }) do
      OperatorChronicle.stub(
        :database_now, -> {
                         later_family_processed = true
                         now
                       },
      ) do
        Rails.error.stub(:report, ->(error, **context) { reported << [error, context] }) do
          assert_same failure, assert_raises(ActiveRecord::StatementInvalid) { RetentionPurgeJob.perform_now }
        end
      end
    end

    assert later_family_processed
    assert_same failure, reported.fetch(0).fetch(0)
    assert_equal "AppPreferenceChronicle", reported.fetch(0).fetch(1).fetch(:context).fetch(:retained_model)
  end
end
