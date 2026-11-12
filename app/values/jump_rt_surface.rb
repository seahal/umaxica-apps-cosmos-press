# typed: false
# frozen_string_literal: true

module JumpRtSurface
  module_function

  # Press owns Edit as a receiver only; it has no surface that signs Jump RTs.
  # External OP hosts and gateway return-token verification are separate contracts.
  ISSUER_ORIGIN_ENV = {}.freeze
  ISSUER_NAMESPACES = ISSUER_ORIGIN_ENV.keys.freeze

  def issuer_origin(namespace)
    normalize_namespace(namespace)
  end

  def issuer_jwks_uri(namespace)
    issuer_origin(namespace)
  end

  def namespace_for_controller(_controller_class_name)
    raise JumpRtConfigurationError, "Press controllers have no Jump RT issuer namespace"
  end

  def normalize_namespace(_namespace)
    raise JumpRtConfigurationError, "Press has no Jump RT issuer surface"
  end

  def normalize_host(host)
    host.to_s.strip.sub(/\Ahttps?:\/\//, "").split("/").first
  end
end
