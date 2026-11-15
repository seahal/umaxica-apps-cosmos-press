# typed: false
# frozen_string_literal: true

require "base64"
require "json"
require "openssl"

module JitSecurityJwtKeyMaterial
  module_function

  MIN_RSA_BITS = 3072
  Error = Class.new(StandardError)

  def parse_private_keyset(raw)
    return {} if raw.blank?

    parsed = JSON.parse(raw)
    raise Error, "must be a JSON object" unless parsed.is_a?(Hash)

    parsed.transform_values { |value| decode_private_key(value) }.compact
  rescue JSON::ParserError => e
    raise Error, "contains invalid JSON: #{e.message}"
  end

  def decode_private_key(value)
    return nil if value.blank?

    raw = value.to_s
    key =
      if raw.start_with?("-----BEGIN PRIVATE KEY-----")
        OpenSSL::PKey.read(raw)
      elsif raw.start_with?("-----BEGIN")
        raise Error, "must be an RSA PKCS#8 private key"
      else
        der = Base64.strict_decode64(raw)
        raise Error, "must be an RSA PKCS#8 private key" unless pkcs8_der?(der)

        OpenSSL::PKey.read(der)
      end

    raise Error, "must be an RSA private key" unless key.is_a?(OpenSSL::PKey::RSA) && key.private?
    raise Error, "RSA private key must be at least #{MIN_RSA_BITS} bits" if key.n.num_bits < MIN_RSA_BITS

    key
  rescue OpenSSL::PKey::PKeyError, ArgumentError, TypeError => e
    raise Error, "contains invalid RSA PKCS#8 key material: #{e.class.name}"
  end

  def pkcs8_der?(der)
    document = OpenSSL::ASN1.decode(der)
    document.is_a?(OpenSSL::ASN1::Sequence) &&
      document.value.size == 3 &&
      document.value[0].is_a?(OpenSSL::ASN1::Integer) &&
      document.value[1].is_a?(OpenSSL::ASN1::Sequence) &&
      document.value[2].is_a?(OpenSSL::ASN1::OctetString)
  rescue OpenSSL::ASN1::ASN1Error
    false
  end
  private_class_method :pkcs8_der?
end
