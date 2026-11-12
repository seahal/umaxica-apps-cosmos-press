# frozen_string_literal: true

# Signs upstream ID Token fixtures for Edit RP tests. Press no longer issues OIDC ID Tokens.
module OidcIdTokenFixtureHelper
  ID_TOKEN_TYPE = "id-token+jwt"

  private

  def oidc_id_token_for_test(client:, resource_type:, nonce:, issuer:, subject:, sid:, issuer_id:,
                             issued_at: Time.current, expires_at: 5.minutes.from_now, acr: "aal1", amr: nil,
                             auth_time: nil, step_up_until: nil)
    issued_at = issued_at.to_time.utc.to_i
    claims = {
      "iss" => issuer,
      "sub" => subject,
      "aud" => [client.client_id],
      "exp" => expires_at.to_time.utc.to_i,
      "iat" => issued_at,
      "nbf" => issued_at,
      "jti" => SecureRandom.uuid,
      "typ" => ID_TOKEN_TYPE,
      "act" => resource_type,
      "sid" => sid,
      "nonce" => nonce,
      "acr" => acr,
    }
    claims["amr"] = Array(amr) if amr.present?
    claims["auth_time"] = auth_time.to_time.utc.to_i if auth_time.present?
    claims["step_up_until"] = step_up_until.to_time.utc.to_i if step_up_until.present?

    JitSecurityJwtKeyring.encode(claims, typ: ID_TOKEN_TYPE, issuer_id:)
  end
end
