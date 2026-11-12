# typed: false
# frozen_string_literal: true

require "test_helper"

class ApplicationPolicyRequestContextTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "own principal policy receives its explicit principal and verified Normal claims" do
    principal = RpEditOrgPrincipal.new(id: 381)
    claims = { "authn_ctx" => "normal" }
    policy = RpPrincipalPolicy.new(principal, user: principal, access_token_claims: claims)

    assert_same principal, policy.user
    assert policy.apply(:show?)
  end

  test "Standby claims may narrow privileges but still permit the authenticated own page" do
    principal = RpEditOrgPrincipal.new(id: 381)
    policy = RpPrincipalPolicy.new(principal, user: principal, access_token_claims: { "authn_ctx" => "standby" })

    assert policy.apply(:show?)
  end

  test "missing malformed or unknown policy claims deny instead of borrowing ambient Normal authority" do
    principal = RpEditOrgPrincipal.new(id: 381)
    [nil, "", 0, [], { "authn_ctx" => "unrecognized" }].each do |claims|
      policy = RpPrincipalPolicy.new(principal, user: principal, access_token_claims: claims)

      assert_not policy.apply(:show?), "non-authoritative claims must deny"
    end
    assert_not RpPrincipalPolicy.new(principal, user: principal).apply(:show?)
  end

  test "an explicitly supplied verified legacy payload without the context claim retains Normal semantics" do
    principal = RpEditOrgPrincipal.new(id: 381)
    policy = RpPrincipalPolicy.new(principal, user: principal, access_token_claims: { "sub" => "external-subject" })

    assert policy.apply(:show?)
  end

  test "another principal is forbidden even with explicit Normal claims" do
    principal = RpEditOrgPrincipal.new(id: 381)
    other = RpEditOrgPrincipal.new(id: 382)
    policy = RpPrincipalPolicy.new(principal, user: other, access_token_claims: { "authn_ctx" => "normal" })

    assert_not policy.apply(:show?)
  end

  test "interleaved policy instances keep their own claims rather than the previous caller authority" do
    principal = RpEditOrgPrincipal.new(id: 381)
    normal = RpPrincipalPolicy.new(principal, user: principal, access_token_claims: { "authn_ctx" => "normal" })
    unknown = RpPrincipalPolicy.new(principal, user: principal, access_token_claims: { "authn_ctx" => "unrecognized" })
    standby = RpPrincipalPolicy.new(principal, user: principal, access_token_claims: { "authn_ctx" => "standby" })

    assert normal.apply(:show?)
    assert_not unknown.apply(:show?)
    assert standby.apply(:show?)
    assert_not unknown.apply(:show?)
    assert normal.apply(:show?)
  end

  test "an upstream successful result cannot grant a domain permission without an explicit principal" do
    result = PublishingAuthorityClient::Result.new(status: :ok, data: {}, errors: nil)
    [nil, false, ""].each do |principal|
      policy = PublishingRemoteResultPolicy.new(
        result, user: principal, access_token_claims: { "authn_ctx" => "normal" },
      )

      assert_not policy.apply(:show?)
    end
  end

  test "concurrently evaluated policy instances keep separate explicit capability contexts" do
    principal = RpEditOrgPrincipal.new(id: 381)
    policies =
      %w(normal unrecognized standby).index_with do |context|
        RpPrincipalPolicy.new(principal, user: principal, access_token_claims: { "authn_ctx" => context })
      end
    ready = Queue.new
    release = Queue.new
    results = Queue.new
    threads =
      policies.map do |context, policy|
        Thread.new do
          ready << true
          release.pop
          results << [context, policy.apply(:show?)]
        end
      end
    threads.length.times { ready.pop }
    threads.length.times { release << true }
    threads.each(&:value)
    outcomes = threads.length.times.to_h { results.pop }

    assert_equal({ "normal" => true, "unrecognized" => false, "standby" => true }, outcomes)
  end
end
