# frozen_string_literal: true

# External OP credentials are signed fixtures; only the Edit RP session is persisted locally.
module RpCellSessionHelper
  def install_rp_cell_operator_jwks_client!
    jwks_uri = OidcIssuer.jwks_uri("operator").to_s
    issuer_id = OidcIssuer.jwt_issuer_id_for_resource_type("operator")
    OidcOpJwksClient::CLIENTS[jwks_uri] = OidcOpJwksClient.new(
      jwks_uri:, fetcher: -> { JitSecurityJwtRegistry.jwks_for(issuer_id).deep_stringify_keys },
    )
  end

  def as_rp_cell(client_id)
    cell = RpCellBinding.for_client(client_id)
    names = %w(UMAXICA_RUNTIME_ROLE UMAXICA_RP_BROWSER_ADMISSION)
    previous = names.index_with { |name| ENV[name] }
    ENV["UMAXICA_RUNTIME_ROLE"] = "#{cell.connection.tr("_", "-")}-#{cell.region}"
    ENV["UMAXICA_RP_BROWSER_ADMISSION"] = "open"
    OidcOpJwksClient::CLIENTS.clear
    yield
  ensure
    previous&.each { |name, value| value.nil? ? ENV.delete(name) : ENV[name] = value }
  end

  def sign_in_edit_rp(subject: "operator:external-reference", sid: SecureRandom.urlsafe_base64(24),
                      authentication_context: "normal", expires_at: 10.minutes.from_now)
    cell = RpCellBinding.for_client("edit-org-ww")
    token_response = rp_cell_test_token_response(
      cell.client_id, subject:, sid:, authentication_context:, expires_at:,
    )
    payload, = JWT.decode(token_response.fetch(:access_token), nil, false)
    enrollment = RpCallbackCommitter.call(
      cell:, issuer: payload.fetch("iss"), subject:, sid:, absolute_expires_at: 1.hour.from_now,
    )
    raise ArgumentError, "cell enrollment failed: #{enrollment.outcome}" unless enrollment.success?

    cookies[OidcRpBrowserCredentialContract::ACCESS_COOKIE] = token_response.fetch(:access_token)
    cookies[OidcRpBrowserCredentialContract::REFRESH_COOKIE] = token_response.fetch(:refresh_token)
    cookies[OidcRpBrowserCredentialContract::SESSION_COOKIE] = enrollment.session.public_id
    [token_response, payload, enrollment.session]
  end

  def rp_cell_test_token_response(client_id, subject:, sid:, authentication_context: "normal",
                                  expires_at: 10.minutes.from_now)
    client = OidcClientRegistry.find!(client_id)
    issued_at = Time.current.utc
    issuer = OidcIssuer.for_client(client)
    issuer_id = OidcIssuer.jwt_issuer_id_for_client(client)
    claims = {
      "iss" => issuer,
      "sub" => subject,
      "aud" => [client.aud],
      "client_id" => client.client_id,
      "sid" => sid,
      "jti" => SecureRandom.uuid,
      "scope" => "openid profile",
      "iat" => issued_at.to_i,
      "nbf" => issued_at.to_i,
      "exp" => expires_at.to_i,
      AuthenticationContextValue::CLAIM => authentication_context,
    }
    access_token = JitSecurityJwtKeyring.encode(claims, typ: "at+jwt", issuer_id:)
    id_token = oidc_id_token_for_test(
      client:, resource_type: "operator", nonce: SecureRandom.urlsafe_base64(24), issuer:, subject:, sid:,
      issuer_id:, issued_at:, expires_at:,
    )
    { access_token:,
      id_token:,
      refresh_token: "#{sid}.#{SecureRandom.urlsafe_base64(32)}",
      expires_in: (expires_at - issued_at).to_i,
      refresh_token_expires_in: 3600, }
  end
end
