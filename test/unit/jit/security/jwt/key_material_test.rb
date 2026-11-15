# frozen_string_literal: true

require "test_helper"
# require "helpers/global_test_support"
require "jit_security_jwt_key_material"

module Jit
  module Security
    module Jwt
      class KeyMaterialTest < ActiveSupport::TestCase
        self.fixture_table_names = []

        setup do
          @key = OpenSSL::PKey::RSA.generate(3072)
          @encoded_key = Base64.strict_encode64(@key.private_to_der)
        end

        test "decodes base64 der rsa private keys" do
          key = JitSecurityJwtKeyMaterial.decode_private_key(@encoded_key)

          assert_kind_of OpenSSL::PKey::RSA, key
          assert_operator key.n.num_bits, :>=, 3072
        end

        test "decodes pem rsa private keys" do
          key = JitSecurityJwtKeyMaterial.decode_private_key(@key.private_to_pem)

          assert_kind_of OpenSSL::PKey::RSA, key
        end

        test "parses private keyset json object" do
          keyset = JitSecurityJwtKeyMaterial.parse_private_keyset(JSON.generate("kid-1" => @encoded_key))

          assert_kind_of OpenSSL::PKey::RSA, keyset.fetch("kid-1")
        end

        test "rejects malformed private keyset json" do
          error =
            assert_raises(JitSecurityJwtKeyMaterial::Error) do
              JitSecurityJwtKeyMaterial.parse_private_keyset("{")
            end

          assert_match(/invalid JSON/, error.message)
        end

        test "rejects non object private keyset json" do
          error =
            assert_raises(JitSecurityJwtKeyMaterial::Error) do
              JitSecurityJwtKeyMaterial.parse_private_keyset(JSON.generate([@encoded_key]))
            end

          assert_match(/JSON object/, error.message)
        end

        test "rejects invalid rsa private key material" do
          error =
            assert_raises(JitSecurityJwtKeyMaterial::Error) do
              JitSecurityJwtKeyMaterial.decode_private_key("not-a-key")
            end

          assert_match(/invalid RSA PKCS#8 key material/, error.message)
        end

        test "rejects 2048-bit RSA private keys" do
          undersized = Base64.strict_encode64(OpenSSL::PKey::RSA.generate(2048).private_to_der)

          error =
            assert_raises(JitSecurityJwtKeyMaterial::Error) do
              JitSecurityJwtKeyMaterial.decode_private_key(undersized)
            end

          assert_match(/at least 3072 bits/, error.message)
        end

        test "rejects EC private keys" do
          legacy_key = Base64.strict_encode64(OpenSSL::PKey::EC.generate("secp384r1").private_to_der)

          error =
            assert_raises(JitSecurityJwtKeyMaterial::Error) do
              JitSecurityJwtKeyMaterial.decode_private_key(legacy_key)
            end

          assert_match(/must be an RSA private key/, error.message)
        end
      end
    end
  end
end
