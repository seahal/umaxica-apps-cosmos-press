# frozen_string_literal: true

require "test_helper"

class SecurityJwtAccessTokenNegativeCasesTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  setup do
    @client = OidcClientRegistry.find!("edit-org-ww")
    @issuer_id = OidcIssuer.jwt_issuer_id_for_client(@client)
    @issuer = OidcIssuer.for_client(@client)
    @key = OpenSSL::PKey::RSA.generate(3072)
    @jwks = OidcOpJwksClient.new(
      jwks_uri: OidcIssuer.jwks_uri("operator").to_s,
      fetcher: -> {
        { "keys" => [JitSecurityJwtJwk.export_public(@key, kid: @header.fetch("kid"))] }
      },
    )
    token = rp_cell_test_token_response(@client.client_id, subject: "external-subject", sid: "external-session")
    @payload, @header = JWT.decode(token.fetch(:access_token), nil, false)
    @header["alg"] = "PS256"
    @header["typ"] = OidcOpAccessTokenVerifier::TOKEN_TYPE
  end

  test "external RP access verification refuses ES384 RS256 PS384 HMAC and none" do
    {
      "ES384" => OpenSSL::PKey::EC.generate("secp384r1"),
      "ES256" => OpenSSL::PKey::EC.generate("prime256v1"),
      "ES512" => OpenSSL::PKey::EC.generate("secp521r1"),
      "RS256" => OpenSSL::PKey::RSA.generate(2048),
      "PS384" => OpenSSL::PKey::RSA.generate(3072),
      "HS256" => "shared-secret",
      "none" => nil,
    }.each do |algorithm, key|
      token = JWT.encode(@payload, key, algorithm, @header.merge("alg" => algorithm))

      assert_not verify(token).success?, "#{algorithm} must be rejected"
    end
  end

  test "external RP access verification refuses a foreign signing key" do
    token = JWT.encode(@payload, OpenSSL::PKey::RSA.generate(3072), "PS256", @header)

    assert_not verify(token).success?
  end

  test "external RP access verification refuses missing and malformed claims" do
    variants = {
      "client_id missing" => @payload.except("client_id"),
      "client_id numeric" => @payload.merge("client_id" => 7),
      "exp missing" => @payload.except("exp"),
      "jti missing" => @payload.except("jti"),
      "iss missing" => @payload.except("iss"),
      "aud empty" => @payload.merge("aud" => []),
      "iat fractional" => @payload.merge("iat" => @payload.fetch("iat") + 0.5),
      "sub numeric" => @payload.merge("sub" => 381),
      "scope array" => @payload.merge("scope" => ["openid"]),
      "scope missing" => @payload.except("scope"),
      "future nbf" => @payload.merge("nbf" => 10.minutes.from_now.to_i),
      "unknown authentication context" => @payload.merge("authn_ctx" => "elevated"),
    }

    variants.each do |name, payload|
      assert_not verify(JWT.encode(payload, @key, "PS256", @header)).success?, name
    end
  end

  test "external RP access verification refuses retired private claim formats" do
    %w(scp act typ).each do |claim|
      payload = @payload.merge(claim => "retired")

      assert_not verify(JWT.encode(payload, @key, "PS256", @header)).success?, claim
    end
  end

  test "external RP access verification refuses another realm issuer audience or client" do
    [
      @payload.merge("scope" => "openid domain:client"),
      @payload.merge("iss" => "https://other.example/issuer"),
      @payload.merge("aud" => ["other-client"]),
      @payload.merge("client_id" => "other-client"),
    ].each do |payload|
      assert_not verify(JWT.encode(payload, @key, "PS256", @header)).success?
    end
  end

  test "external RP access verification refuses wrong absent and legacy JOSE types" do
    [@header.except("typ"), @header.merge("typ" => "JWT"),
     @header.merge("typ" => "auth-access-token;client"),].each do |header|
      assert_not verify(JWT.encode(@payload, @key, "PS256", header)).success?
    end
  end

  test "keyring encoding requires explicit JOSE type and preserves header ownership" do
    assert_raises(ArgumentError) { JitSecurityJwtKeyring.encode({ "typ" => "x+jwt" }, typ: nil, issuer_id: @issuer_id) }

    token = JitSecurityJwtKeyring.encode({ "typ" => "payload-typ" }, typ: "at+jwt", issuer_id: @issuer_id)

    assert_equal "at+jwt", JWT.decode(token, nil, false)[1].fetch("typ")
    assert_equal "PS256", JWT.decode(token, nil, false)[1].fetch("alg")
  end

  test "external RP access verification rejects 2048-bit RSA as below the 3072-bit minimum" do
    undersized_key = OpenSSL::PKey::RSA.generate(2048)
    kid = @header.fetch("kid")
    undersized_jwk = JWT::JWK.new(undersized_key, kid: kid).export.stringify_keys.merge(
      "alg" => "PS256", "use" => "sig",
    )
    client = OidcOpJwksClient.new(
      jwks_uri: OidcIssuer.jwks_uri("operator").to_s,
      fetcher: -> { { "keys" => [undersized_jwk] } },
    )

    result = verify_with_jwks(JWT.encode(@payload, undersized_key, "PS256", @header), client)

    assert_not_predicate result, :success?
  end

  private

  def verify(token)
    verify_with_jwks(token, @jwks)
  end

  def verify_with_jwks(token, jwks_client)
    OidcOpAccessTokenVerifier.new(
      access_token: token, client_id: @client.client_id, realm: "org", issuer: @issuer,
      audience: @client.aud, jwks_client: jwks_client,
    ).call
  end
end
