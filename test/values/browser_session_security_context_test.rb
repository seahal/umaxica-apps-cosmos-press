# typed: false
# frozen_string_literal: true

require "test_helper"

class BrowserSessionSecurityContextTest < ActiveSupport::TestCase
  test "is active when each bound session is active" do
    browser_session = Struct.new(:usable?).new(true)
    root_token = Struct.new(:active_status?).new(true)
    rp_session = Struct.new(:active?).new(true)
    context = BrowserSessionSecurityContext.new(
      resource: Object.new,
      browser_session: browser_session,
      root_token: root_token,
      rp_session: rp_session,
      access_payload: {},
    )

    assert_predicate context, :active?
  end

  test "exposes the public identifiers of both bound sessions" do
    root_token = Struct.new(:public_id).new("root-session-1")
    rp_session = Struct.new(:public_id).new("rp-session-1")
    context = BrowserSessionSecurityContext.new(
      resource: Object.new,
      browser_session: nil,
      root_token: root_token,
      rp_session: rp_session,
      access_payload: {},
    )

    assert_equal "root-session-1", context.root_session_public_id
    assert_equal "rp-session-1", context.rp_session_public_id
    assert_nil BrowserSessionSecurityContext.new(
      resource: nil,
      browser_session: nil,
      root_token: nil,
      rp_session: nil,
      access_payload: {},
    ).root_session_public_id
  end
end
