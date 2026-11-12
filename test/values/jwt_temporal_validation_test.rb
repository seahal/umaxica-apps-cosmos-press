# typed: false
# frozen_string_literal: true

require "test_helper"

class JwtTemporalValidationTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "separated RP access verification enforces the fixed thirty second iat nbf and exp boundaries" do
    travel_to Time.utc(2026, 10, 22, 12) do
      now = Time.current.to_i
      issuer = "https://visa.example/org"
      key = OpenSSL::PKey::EC.generate("secp384r1")
      jwk = JitSecurityJwtJwk.export_public(key, kid: "temporal-key")
      jwks_client = OidcOpJwksClient.new(
        jwks_uri: "https://base.example/.well-known/jwks.json",
        fetcher: -> { { "keys" => [jwk] } },
      )
      payload = {
        "iss" => issuer,
        "aud" => ["edit-org-ww"],
        "exp" => now + 240,
        "iat" => now - 60,
        "nbf" => now - 60,
        "sub" => "temporal-subject",
        "sid" => "temporal-session",
        "jti" => "temporal-jti",
        "client_id" => "edit-org-ww",
        "scope" => "openid domain:operator",
        "authn_ctx" => "normal",
      }
      cases = [
        ["iat", now + 29, true], ["iat", now + 30, true], ["iat", now + 31, false],
        ["nbf", now + 29, true], ["nbf", now + 30, true], ["nbf", now + 31, false],
        ["exp", now - 29, true], ["exp", now - 30, false], ["exp", now - 31, false],
      ]
      cases.each do |claim, value, accepted|
        token = JWT.encode(payload.merge(claim => value), key, "ES384", { typ: "at+jwt", kid: "temporal-key" })
        result = OidcOpAccessTokenVerifier.new(
          access_token: token, client_id: "edit-org-ww", realm: "org", issuer: issuer,
          audience: "edit-org-ww", jwks_client: jwks_client,
        ).call

        assert_equal accepted, result.success?, "#{claim}=#{value - now}"
      end
    end
  end

  test "separated RP ID verification enforces the fixed thirty second iat nbf and exp boundaries" do
    travel_to Time.utc(2026, 10, 22, 12) do
      now = Time.current.to_i
      issuer = "https://visa.example/org"
      key = OpenSSL::PKey::EC.generate("secp384r1")
      jwk = JitSecurityJwtJwk.export_public(key, kid: "temporal-key")
      jwks_client = OidcOpJwksClient.new(
        jwks_uri: "https://base.example/.well-known/jwks.json",
        fetcher: -> { { "keys" => [jwk] } },
      )
      payload = {
        "iss" => issuer,
        "aud" => ["edit-org-ww"],
        "exp" => now + 240,
        "iat" => now - 60,
        "nbf" => now - 60,
        "sub" => "temporal-subject",
        "sid" => "temporal-session",
        "jti" => "temporal-jti",
        "nonce" => "temporal-nonce",
        "typ" => "id-token+jwt",
        "act" => "operator",
      }
      cases = [
        ["iat", now + 29, true], ["iat", now + 30, true], ["iat", now + 31, false],
        ["nbf", now + 29, true], ["nbf", now + 30, true], ["nbf", now + 31, false],
        ["exp", now - 29, true], ["exp", now - 30, false], ["exp", now - 31, false],
      ]
      cases.each do |claim, value, accepted|
        token = JWT.encode(payload.merge(claim => value), key, "ES384", { typ: "id-token+jwt", kid: "temporal-key" })
        result = OidcOpIdTokenVerifier.new(
          id_token: token, client_id: "edit-org-ww", realm: "org", issuer: issuer,
          expected_nonce: "temporal-nonce", jwks_client: jwks_client,
        ).call

        assert_equal accepted, result.success?, "#{claim}=#{value - now}"
      end
    end
  end

  test "separated RP logout verification enforces the fixed thirty second iat nbf and exp boundaries" do
    travel_to Time.utc(2026, 10, 22, 12) do
      now = Time.current.to_i
      issuer = "https://visa.example/org"
      key = OpenSSL::PKey::EC.generate("secp384r1")
      jwk = JitSecurityJwtJwk.export_public(key, kid: "temporal-key")
      jwks_client = OidcOpJwksClient.new(
        jwks_uri: "https://base.example/.well-known/jwks.json",
        fetcher: -> { { "keys" => [jwk] } },
      )
      payload = {
        "iss" => issuer,
        "aud" => ["edit-org-ww"],
        "exp" => now + 240,
        "iat" => now - 60,
        "nbf" => now - 60,
        "sub" => "temporal-subject",
        "sid" => "temporal-session",
        "jti" => "temporal-jti",
        "events" => { OidcOpLogoutTokenVerifier::EVENT => {} },
      }
      cases = [
        ["iat", now + 29, true], ["iat", now + 30, true], ["iat", now + 31, false],
        ["nbf", now + 29, true], ["nbf", now + 30, true], ["nbf", now + 31, false],
        ["exp", now - 29, true], ["exp", now - 30, false], ["exp", now - 31, false],
      ]
      cases.each do |claim, value, accepted|
        token = JWT.encode(payload.merge(claim => value), key, "ES384", { typ: "logout+jwt", kid: "temporal-key" })
        result = OidcOpLogoutTokenVerifier.new(
          logout_token: token, client_id: "edit-org-ww", issuer: issuer, jwks_client: jwks_client,
        ).call

        assert_equal accepted, result.success?, "#{claim}=#{value - now}"
      end
    end
  end

  test "separated RP logout rejects empty and reversed token validity intervals" do
    travel_to Time.utc(2026, 10, 22, 12) do
      now = Time.current.to_i
      issuer = "https://visa.example/org"
      key = OpenSSL::PKey::EC.generate("secp384r1")
      jwk = JitSecurityJwtJwk.export_public(key, kid: "interval-key")
      jwks = OidcOpJwksClient.new(
        jwks_uri: "https://base.example/.well-known/jwks.json", fetcher: -> { { "keys" => [jwk] } },
      )
      payload = {
        "iss" => issuer,
        "aud" => ["edit-org-ww"],
        "exp" => now + 120,
        "iat" => now,
        "sid" => "session",
        "jti" => "jti",
        "events" => { OidcOpLogoutTokenVerifier::EVENT => {} },
      }
      [
        [{ "iat" => now + 6, "exp" => now + 5 }, false],
        [{ "iat" => now + 5, "exp" => now + 5 }, false],
        [{ "iat" => now, "exp" => now + 1 }, true],
        [{ "iat" => now, "exp" => now + 300 }, true],
        [{ "iat" => now, "exp" => now + 301 }, false],
        [{ "iat" => now + 0.25, "exp" => now + 1.25 }, true],
      ].each do |overrides, accepted|
        token = JWT.encode(payload.merge(overrides), key, "ES384", { typ: "logout+jwt", kid: "interval-key" })
        result = OidcOpLogoutTokenVerifier.new(
          logout_token: token, client_id: "edit-org-ww", issuer: issuer, jwks_client: jwks,
        ).call

        assert_equal accepted, result.success?, overrides.inspect
      end
    end
  end

  test "outbound client assertions preserve the supplied issue time without local inbound verification" do
    travel_to Time.utc(2026, 10, 22, 12) do
      now = Time.current
      token_url = OidcIssuer.token_endpoint("operator")
      [29, 30, 31].each do |offset|
        token = OidcClientAssertionJwt.issue(client_id: "edit-org-ww", token_url:, now: now + offset)
        payload, = JWT.decode(token, nil, false)

        assert_equal (now + offset).to_i, payload.fetch("iat")
        assert_raises(DependencyUnavailableError) do
          OidcClientAssertionJwt.valid?(client_id: "edit-org-ww", assertion: token, token_url:, now:)
        end
      end
    end
  end
end
