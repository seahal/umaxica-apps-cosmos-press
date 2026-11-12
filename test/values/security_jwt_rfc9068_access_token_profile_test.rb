# frozen_string_literal: true

require "test_helper"

class SecurityJwtRfc9068AccessTokenProfileTest < ActiveSupport::TestCase
  test "access token headers require the configured algorithm type and key id" do
    valid = { "alg" => "ES384", "typ" => "at+jwt", "kid" => "key-1" }

    assert SecurityJwtRfc9068AccessTokenProfile.header_valid?(valid)
    [
      nil,
      "not-a-header",
      {},
      valid.except("alg"),
      valid.merge("alg" => "none"),
      valid.merge("typ" => "JWT"),
      valid.merge("kid" => ""),
    ].each do |header|
      assert_not SecurityJwtRfc9068AccessTokenProfile.header_valid?(header), header.inspect
    end
    assert_equal "MISSING_KID", SecurityJwtRfc9068AccessTokenProfile.header_rejection_reason(valid.except("kid"))
    assert_equal "ALG_MISMATCH",
                 SecurityJwtRfc9068AccessTokenProfile.header_rejection_reason(valid.merge("alg" => "RS256"))
  end

  test "access token header rejection reasons classify malformed and unsupported headers" do
    cases = [
      [nil, "MALFORMED_TOKEN"],
      ["not-a-header", "MALFORMED_TOKEN"],
      [{}, "MALFORMED_TOKEN"],
      [{ "alg" => "" }, "MALFORMED_TOKEN"],
      [{ "alg" => "ES384" }, "MISSING_KID"],
      [{ "alg" => "ES384", "kid" => "" }, "MISSING_KID"],
      [{ "alg" => "none", "kid" => "key-1" }, "ALG_NONE"],
      [{ "alg" => "RS256", "kid" => "key-1" }, "ALG_MISMATCH"],
      [{ "alg" => "ES384", "kid" => "key-1" }, "MISSING_TYP"],
      [{ "alg" => "ES384", "kid" => "key-1", "typ" => "" }, "MISSING_TYP"],
      [{ "alg" => "ES384", "kid" => "key-1", "typ" => "JWT" }, "TYP_MISMATCH"],
    ]

    cases.each do |header, expected_reason|
      assert_equal expected_reason, SecurityJwtRfc9068AccessTokenProfile.header_rejection_reason(header),
                   header.inspect
    end
  end

  test "production issuer and audience identifiers reject every non-production marker class" do
    [
      "localhost",
      "127.0.0.1",
      "https://[::1]",
      "https://issuer.example.test",
      "development issuer",
      "test audience",
    ].each do |identifier|
      error =
        assert_raises(ArgumentError) do
          SecurityJwtRfc9068AccessTokenProfile.assert_production_identifiers!(
            [identifier], label: "AUTH_JWT identifiers", production: true,
          )
        end

      assert_equal "AUTH_JWT identifiers must not include non-production identifiers: #{identifier}", error.message
    end
  end

  test "production identifier checks allow public values and do not restrict non-production values" do
    assert_nil SecurityJwtRfc9068AccessTokenProfile.assert_production_identifiers!(
      ["https://issuer.example.com", "umaxica-api-app"], label: "AUTH_JWT identifiers", production: true,
    )
    assert_nil SecurityJwtRfc9068AccessTokenProfile.assert_production_identifiers!(
      ["localhost"], label: "AUTH_JWT identifiers", production: false,
    )
  end

  test "Jump RT encoding places its token type and key id in the JOSE header" do
    private_key = OpenSSL::PKey::EC.generate("secp384r1")
    token = SecurityJwtJumpRtTokenCodec.encode({ "sub" => "jump-redirect" }, private_key:, kid: "jump-key-1")
    _payload, header = JWT.decode(token, nil, false)

    assert_equal "ES384", header.fetch("alg")
    assert_equal "JWT", header.fetch("typ")
    assert_equal "jump-key-1", header.fetch("kid")
  end

  test "structural claim validation accepts scalar audiences and rejects invalid audience shapes" do
    payload = {
      "iss" => "https://issuer.example",
      "exp" => 1.hour.from_now.to_i,
      "aud" => "client-audience",
      "sub" => "subject",
      "client_id" => "client-id",
      "iat" => Time.current.to_i,
      "jti" => "token-id",
      "scope" => "domain:client",
    }

    assert SecurityJwtRfc9068AccessTokenProfile.claims_structurally_valid?(payload)
    assert SecurityJwtRfc9068AccessTokenProfile.claims_structurally_valid?(payload.merge("aud" => ["client-audience"]))
    assert_not SecurityJwtRfc9068AccessTokenProfile.claims_structurally_valid?(payload.merge("aud" => []))
    assert_not SecurityJwtRfc9068AccessTokenProfile.claims_structurally_valid?(payload.merge("aud" => ["client", 1]))
    assert_not SecurityJwtRfc9068AccessTokenProfile.claims_structurally_valid?(payload.merge("aud" => 1))
  end
end
