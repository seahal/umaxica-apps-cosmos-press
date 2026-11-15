# frozen_string_literal: true

require "test_helper"
# require "helpers/global_test_support"
require "jit_security_jwt_jwk"

module Jit
  module Security
    module Jwt
      class JwkTest < ActiveSupport::TestCase
        self.fixture_table_names = []

        setup do
          @key = OpenSSL::PKey::RSA.generate(3072)
          @public_jwk = JitSecurityJwtJwk.export_public(@key, kid: "kid-1")
        end

        test "exports public jwk without private material" do
          assert_equal "kid-1", @public_jwk.fetch("kid")
          assert_equal JitSecurityJwtJwk::ALGORITHM, @public_jwk.fetch("alg")
          assert_equal "sig", @public_jwk.fetch("use")
          assert_equal "RSA", @public_jwk.fetch("kty")
          assert_operator JitSecurityJwtJwk.import_public_key(@public_jwk).n.num_bits, :>=, 3072
          assert_empty JitSecurityJwtJwk::PRIVATE_FIELDS & @public_jwk.keys
        end

        test "normalizes valid public jwk" do
          normalized = JitSecurityJwtJwk.normalize_public(@public_jwk.merge(extra: "ignored"))

          assert_equal @public_jwk, normalized
        end

        test "rejects public jwk with private material" do
          error =
            assert_raises(JitSecurityJwtJwk::Error) do
              JitSecurityJwtJwk.normalize_public(@public_jwk.merge("d" => "secret"))
            end

          assert_match(/private JWK material/, error.message)
        end

        test "rejects unexpected algorithm" do
          error =
            assert_raises(JitSecurityJwtJwk::Error) do
              JitSecurityJwtJwk.normalize_public(@public_jwk.merge("alg" => "HS256"))
            end

          assert_match(/alg must be PS256/, error.message)
        end

        test "rejects incomplete public jwk" do
          error =
            assert_raises(JitSecurityJwtJwk::Error) do
              JitSecurityJwtJwk.normalize_public(@public_jwk.except("n"))
            end

          assert_match(/missing n/, error.message)
        end

        test "imports valid public jwk material" do
          assert_kind_of OpenSSL::PKey::RSA, JitSecurityJwtJwk.import_public_key(@public_jwk)
        end

        test "accepts 4096-bit RSA public keys" do
          jwk = JitSecurityJwtJwk.export_public(OpenSSL::PKey::RSA.generate(4096), kid: "rsa-4096")

          assert_operator JitSecurityJwtJwk.import_public_key(jwk).n.num_bits, :>=, 4096
        end

        test "rejects 2048-bit RSA keys as the nearest practical size below the 3072-bit minimum" do
          jwk = JWT::JWK.new(OpenSSL::PKey::RSA.generate(2048), kid: "rsa-2048").export.stringify_keys.merge(
            "alg" => "PS256", "use" => "sig",
          )

          error = assert_raises(JitSecurityJwtJwk::Error) { JitSecurityJwtJwk.normalize_public(jwk) }

          assert_match(/at least 3072 bits/, error.message)
        end

        test "rejects EC keys from the first-party JWT key policy" do
          ec_jwk = JWT::JWK.new(OpenSSL::PKey::EC.generate("secp384r1"), kid: "legacy-ec")
            .export.stringify_keys.merge("alg" => "ES384", "use" => "sig")

          error = assert_raises(JitSecurityJwtJwk::Error) { JitSecurityJwtJwk.normalize_public(ec_jwk) }

          assert_match(/missing n|alg must be PS256|kty must be RSA/, error.message)
        end
      end
    end
  end
end
