# frozen_string_literal: true

require "test_helper"
# require "helpers/global_test_support"
require "base64"

class OidcClientAssertionJwtTest < ActiveSupport::TestCase
  self.fixture_table_names = []
  test "issue returns nil when the client is not registered" do
    assert_nil OidcClientAssertionJwt.issue(client_id: "missing_client", token_url: "https://id.example/token")
  end

  test "issue returns nil when local key refresh still cannot resolve the configured key" do
    previous_issuers = JitSecurityJwtRegistry.instance_variable_get(:@issuers)

    with_env(
      "OIDC_CLIENT_EDIT_ORG_WW_ACTIVE_KID" => nil,
      "OIDC_CLIENT_EDIT_ORG_WW_PRIVATE_KEY" => nil,
      "OIDC_CLIENT_EDIT_ORG_WW_PUBLIC_KEYSET" => nil,
    ) do
      JitSecurityJwtRegistry.reload!

      OidcClientAssertionJwt.stub(:refresh_local_key_material!, true) do
        OidcClientAssertionJwt.stub(
          :issue_with_configured_key, ->(**) {
                                        raise JitSecurityJwtRegistry::ConfigurationError
                                      },
        ) do
          assert_nil OidcClientAssertionJwt.issue(client_id: "edit-org-ww", token_url: "https://id.example/token")
        end
      end
    end
  ensure
    JitSecurityJwtRegistry.instance_variable_set(:@issuers, previous_issuers)
  end

  test "issue refreshes local key material once when the registry is missing a client assertion key" do
    token_url = "https://log.umaxica.app/oauth/token"
    key = OpenSSL::PKey::RSA.generate(3072)
    previous = JitSecurityJwtRegistry.instance_variable_get(:@issuers)
    installed = false

    with_env(
      "OIDC_CLIENT_EDIT_ORG_WW_ACTIVE_KID" => nil,
      "OIDC_CLIENT_EDIT_ORG_WW_PRIVATE_KEY" => nil,
      "OIDC_CLIENT_EDIT_ORG_WW_PUBLIC_KEYSET" => nil,
    ) do
      JitSecurityJwtRegistry.reload!

      assert_nil JitSecurityJwtRegistry.private_key_for("oidc_client:EDIT_ORG_WW")

      installer =
        lambda do |**|
          installed = true
          ENV["OIDC_CLIENT_EDIT_ORG_WW_ACTIVE_KID"] = "core-app-oidc-recovered"
          ENV["OIDC_CLIENT_EDIT_ORG_WW_PRIVATE_KEY"] = Base64.strict_encode64(key.private_to_der)
          true
        end

      JitSecurityJwtLocalKeysetInstaller.stub(:install!, installer) do
        assertion = OidcClientAssertionJwt.issue(client_id: "edit-org-ww", token_url: token_url)

        assert installed
        assert_predicate assertion, :present?
      end
    ensure
      JitSecurityJwtRegistry.instance_variable_set(:@issuers, previous)
    end
  end

  test "step-up expectation values require two non-empty strings" do
    assert_raises(ArgumentError) do
      OidcClientAssertionStepUpExpectationValue.new(grant: "", subject: "subject-ref")
    end
    assert_raises(ArgumentError) do
      OidcClientAssertionStepUpExpectationValue.new(grant: "grant-public-id", subject: nil)
    end
  end

  test "local inbound assertion verification explicitly refuses unavailable replay authority" do
    token_url = "https://log.umaxica.app/oauth/token"
    token = OidcClientAssertionJwt.issue(client_id: "edit-org-ww", token_url:)

    assert_predicate token, :present?
    assert_raises(DependencyUnavailableError) do
      OidcClientAssertionJwt.verify(client_id: "edit-org-ww", assertion: token, token_url:)
    end
    assert_raises(DependencyUnavailableError) do
      OidcClientAssertionJwt.valid?(client_id: "edit-org-ww", assertion: token, token_url:)
    end
  end

  test "outbound assertion carries the registered client audience lifetime and unique identifier" do
    now = Time.utc(2026, 11, 1)
    token_url = "https://log.umaxica.app/oauth/token"
    token = OidcClientAssertionJwt.issue(client_id: "edit-org-ww", token_url:, now:, jti: "external-request")
    payload, header = JWT.decode(token, nil, false)

    assert_equal "edit-org-ww", payload.fetch("iss")
    assert_equal "edit-org-ww", payload.fetch("sub")
    assert_equal token_url, payload.fetch("aud")
    assert_equal now.to_i, payload.fetch("iat")
    assert_equal (now + 5.minutes).to_i, payload.fetch("exp")
    assert_equal "external-request", payload.fetch("jti")
    assert_equal OidcClientAssertionJwt::TOKEN_TYPE, header.fetch("typ")
    assert_equal "PS256", header.fetch("alg")
    assert_not payload.key?("step_up_grant")
    assert_not payload.key?("step_up_sub")
  end

  private

  def with_oidc_client_key(namespace)
    key = OpenSSL::PKey::RSA.generate(3072)
    kid = "#{namespace.downcase.tr("_", "-")}-oidc-test"
    env = {
      "OIDC_CLIENT_#{namespace}_ACTIVE_KID" => kid,
      "OIDC_CLIENT_#{namespace}_PRIVATE_KEY" => Base64.strict_encode64(key.private_to_der),
    }
    previous = JitSecurityJwtRegistry.instance_variable_get(:@issuers)

    with_env(env) do
      JitSecurityJwtRegistry.reload!
      yield
    ensure
      JitSecurityJwtRegistry.instance_variable_set(:@issuers, previous)
    end
  end

  def with_env(values)
    previous = {}
    values.each do |key, value|
      previous[key] = ENV[key]
      value.nil? ? ENV.delete(key) : ENV[key] = value
    end
    yield
  ensure
    previous.each do |key, value|
      value.nil? ? ENV.delete(key) : ENV[key] = value
    end
  end
end
