# frozen_string_literal: true
# typed: false

# == Schema Information
#
# Table name: org_preference_chronicles
# Database name: chronicle
#
#  id             :bigint           not null, primary key
#  actor_type     :text             default(""), not null
#  context        :jsonb            not null
#  current_value  :text             default(""), not null
#  discard_at   :datetime         default(Infinity), not null
#  ip_address     :inet             default(#<IPAddr: IPv4:0.0.0.0/255.255.255.255>), not null
#  occurred_at    :datetime         not null
#  previous_value :text             default(""), not null
#  purge_eligible_at      :datetime         not null
#  subject_type   :text             not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  actor_id       :bigint           default(0), not null
#  event_id       :bigint           default(0), not null
#  level_id       :bigint           default(0), not null
#  subject_id     :bigint           not null
#
# Indexes
#
#  idx_on_subject_type_subject_id_occurred_at_org_pref          (subject_type,subject_id,occurred_at)
#  index_org_preference_chronicles_on_actor_id_and_occurred_at  (actor_id,occurred_at)
#  index_org_preference_chronicles_on_actor_type_and_actor_id   (actor_type,actor_id)
#  index_org_preference_chronicles_on_event_id                  (event_id)
#  index_org_preference_chronicles_on_level_id                  (level_id)
#  index_org_preference_chronicles_on_occurred_at               (occurred_at)
#  index_org_preference_chronicles_on_purge_eligible_at                 (purge_eligible_at)
#  index_org_preference_chronicles_on_subject_id                (subject_id)
#
# Foreign Keys
#
#  fk_rails_...  (event_id => org_preference_chronicle_events.id)
#  fk_rails_...  (level_id => org_preference_chronicle_levels.id)
#

require "test_helper"

class OrgPreferenceChronicleTest < ActiveSupport::TestCase
  fixtures :org_preference_chronicles,
           :org_preference_chronicle_events,
           :org_preference_chronicle_levels

  setup do
    @audit = org_preference_chronicles(:one)
  end

  test "historical preference identity remains scalar and authority is unavailable" do
    assert_equal "OrgPreference", @audit.subject_type
    assert_kind_of Integer, @audit.subject_id
    assert_raises(GovernanceUnavailableError) { @audit.org_preference }
    assert_raises(GovernanceUnavailableError) { @audit.org_preference = Object.new }
  end

  test "uses bigint primary key" do
    assert_kind_of Integer, @audit.id
  end

  test "audit writer and purge locks are acquired within a Chronicle transaction" do
    OrgPreferenceChronicle.transaction do
      assert_kind_of PG::Result, OrgPreferenceChronicle.lock_preference_audit_writers!
      assert_kind_of PG::Result, OrgPreferenceChronicle.lock_preference_audit_for_purge!
    end
  end

  test "belongs to org_preference_chronicle_level" do
    assert_equal org_preference_chronicle_levels(:info), @audit.org_preference_chronicle_level
  end

  test "belongs to org_preference_chronicle_event" do
    assert_equal org_preference_chronicle_events(:create_new_preference_token), @audit.org_preference_chronicle_event
  end

  test "validates presence of subject_id" do
    @audit.subject_type = "SomeOtherType"
    @audit.subject_id = nil

    assert_raises(ActiveRecord::NotNullViolation) { @audit.save!(validate: false) }
  end

  test "validates presence of subject_type" do
    @audit.subject_type = nil

    assert_not @audit.valid?
    assert_includes @audit.errors[:subject_type], I18n.t("errors.messages.blank")
  end
end
