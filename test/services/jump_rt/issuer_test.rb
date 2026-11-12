# typed: false
# frozen_string_literal: true

require "test_helper"

class JumpRtIssuerTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "Press refuses token issuance for its receiver and every foreign issuer namespace" do
    ["EDIT_ORG", "AUTH_APP", "AUTH_ORG", "BASE_APP", "BASE_ORG", "VISA_APP", "VISA_ORG",
     "CORE_APP", "CORE_ORG", "WARP_APP", "WARP_ORG", "PALM_APP", "JUMP_APP", nil, "",].each do |namespace|
      assert_raises(JumpRtConfigurationError) do
        JumpRtIssuer.call(namespace: namespace, url: "https://target.example.invalid/", dst: "internal")
      end
    end
  end

  test "issuer call rejects a destination outside its allowed set before signing" do
    # Press has no issuer namespace; isolate the public destination guard without adding one.
    JumpRtSurface.stub(:normalize_namespace, ->(namespace) { namespace }) do
      issuer = JumpRtIssuer.new(
        namespace: "UNOWNED_TEST_NAMESPACE", url: "https://target.example.invalid/", dst: "external",
        ttl: 30, now: Time.zone.at(1_800_000_000), jti: "synthetic-jti",
      )

      assert_nil issuer.call
    end
  end

  test "Jump RT host normalization removes a scheme and path" do
    assert_equal "issuer.example.invalid", JumpRtSurface.normalize_host("https://issuer.example.invalid/path")
    assert_equal "issuer.example.invalid", JumpRtSurface.normalize_host("issuer.example.invalid")
  end

  test "Edit remains an OIDC client without acquiring a Jump surface signing identity" do
    assert_raises(JitSecurityJwtRegistry::ConfigurationError) { JitSecurityJwtRegistry.surface("EDIT_ORG") }
    assert_equal "EDIT_ORG_WW", JitSecurityJwtRegistry.oidc_client("EDIT_ORG_WW").namespace
    assert_equal "edit-org-ww", OidcClientRegistry.find!("edit-org-ww").client_id
  end

  test "shared codec rejects a case variant algorithm header" do
    assert_not SecurityJwtJumpRtTokenCodec.valid_header?({ "typ" => "JWT", "alg" => "eS384", "kid" => "kid-1" })
  end

  test "shared codec kid validation preserves printable length boundaries and control rejection" do
    assert SecurityJwtJumpRtTokenCodec.valid_kid?("k" * 127)
    assert SecurityJwtJumpRtTokenCodec.valid_kid?("k" * 128)
    assert_not SecurityJwtJumpRtTokenCodec.valid_kid?("k" * 129)
    assert_not SecurityJwtJumpRtTokenCodec.valid_kid?("bad\nkid")
  end

  test "shared codec fixes the replay policy to reuse" do
    payload = SecurityJwtJumpRtTokenCodec.build_issue_payload(
      issuer: "https://issuer.example.invalid", normalized_url: "https://target.example.invalid/", dst: "internal",
      ttl: 30, now: Time.zone.at(1_800_000_000), jti: "synthetic-jti", audience: "https://gateway.example.invalid",
    )

    assert_equal "reuse", payload.fetch(:rpl)
    assert_raises(ArgumentError) do
      SecurityJwtJumpRtTokenCodec.build_issue_payload(
        issuer: "https://issuer.example.invalid", normalized_url: "https://target.example.invalid/", dst: "internal",
        replay_policy: "once", ttl: 30, now: Time.zone.at(1_800_000_000), jti: "synthetic-jti",
        audience: "https://gateway.example.invalid",
      )
    end
  end
end
