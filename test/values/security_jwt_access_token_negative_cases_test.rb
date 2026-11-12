# frozen_string_literal: true

require "test_helper"

class SecurityJwtAccessTokenNegativeCasesTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  setup do
    @client = OidcClientRegistry.find!("edit-org-ww")
    @issuer_id = OidcIssuer.jwt_issuer_id_for_client(@client)
    @issuer = OidcIssuer.for_client(@client)
    @key = JitSecurityJwtRegistry.private_key_for(@issuer_id)
    @jwks = OidcOpJwksClient.new(
      jwks_uri: OidcIssuer.jwks_uri("operator").to_s,
      fetcher: -> { JitSecurityJwtRegistry.jwks_for(@issuer_id).deep_stringify_keys },
    )
    token = rp_cell_test_token_response(@client.client_id, subject: "external-subject", sid: "external-session")
    @payload, @header = JWT.decode(token.fetch(:access_token), nil, false)
  end

  test "external RP access verification refuses every algorithm other than ES384" do
    {
      "ES256" => OpenSSL::PKey::EC.generate("prime256v1"),
      "ES512" => OpenSSL::PKey::EC.generate("secp521r1"),
      "RS256" => OpenSSL::PKey::RSA.generate(2048),
      "PS256" => OpenSSL::PKey::RSA.generate(2048),
      "HS256" => "shared-secret",
      "none" => nil,
    }.each do |algorithm, key|
      token = JWT.encode(@payload, key, algorithm, @header.merge("alg" => algorithm))

      assert_not verify(token).success?, "#{algorithm} must be rejected"
    end
  end

  test "external RP access verification refuses a foreign signing key" do
    token = JWT.encode(@payload, OpenSSL::PKey::EC.generate("secp384r1"), "ES384", @header)

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
      assert_not verify(JWT.encode(payload, @key, "ES384", @header)).success?, name
    end
  end

  test "external RP access verification refuses retired private claim formats" do
    %w(scp act typ).each do |claim|
      payload = @payload.merge(claim => "retired")

      assert_not verify(JWT.encode(payload, @key, "ES384", @header)).success?, claim
    end
  end

  test "external RP access verification refuses another realm issuer audience or client" do
    [
      @payload.merge("scope" => "openid domain:client"),
      @payload.merge("iss" => "https://other.example/issuer"),
      @payload.merge("aud" => ["other-client"]),
      @payload.merge("client_id" => "other-client"),
    ].each do |payload|
      assert_not verify(JWT.encode(payload, @key, "ES384", @header)).success?
    end
  end

  test "external RP access verification refuses wrong absent and legacy JOSE types" do
    [@header.except("typ"), @header.merge("typ" => "JWT"),
     @header.merge("typ" => "auth-access-token;client"),].each do |header|
      assert_not verify(JWT.encode(@payload, @key, "ES384", header)).success?
    end
  end

  test "keyring encoding requires explicit JOSE type and preserves header ownership" do
    assert_raises(ArgumentError) { JitSecurityJwtKeyring.encode({ "typ" => "x+jwt" }, typ: nil, issuer_id: @issuer_id) }

    token = JitSecurityJwtKeyring.encode({ "typ" => "payload-typ" }, typ: "at+jwt", issuer_id: @issuer_id)

    assert_equal "at+jwt", JWT.decode(token, nil, false)[1].fetch("typ")
  end

  private

  def verify(token)
    OidcOpAccessTokenVerifier.new(
      access_token: token, client_id: @client.client_id, realm: "org", issuer: @issuer,
      audience: @client.aud, jwks_client: @jwks,
    ).call
  end
end
