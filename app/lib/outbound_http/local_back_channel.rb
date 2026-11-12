# typed: false
# frozen_string_literal: true

module OutboundHttp
  # Publishing's Edit authority runs in this process. Access and Governance remain external
  # services, including in development; their configured URLs retain their original destination.
  # Only the owned Edit origin uses this process's local HTTP listener.
  module LocalBackChannel
    module_function

    def url(public_url)
      return public_url unless Rails.env.local?

      uri = URI.parse(public_url)
      return public_url unless uri.is_a?(URI::HTTP) && owned_host?(uri.host)

      uri.scheme = "http"
      uri.port = local_port
      uri.to_s
    rescue URI::InvalidURIError
      public_url
    end

    # HTTPS is required except for the exact local form `url` produces.
    def require_https?(url)
      return true unless Rails.env.local?

      uri = URI.parse(url)
      !(uri.scheme == "http" && owned_host?(uri.host) && uri.port == local_port && uri.userinfo.blank?)
    rescue URI::InvalidURIError
      true
    end

    def owned_host?(host)
      hosts = Rails.configuration.x.boot_config.fetch(:hosts)
      hosts.edit_staff.host.to_s.casecmp?(host.to_s)
    end

    def local_port
      port = Integer(ENV.fetch("PORT"), 10)
      raise ArgumentError, "PORT must be between 1 and 65535" unless (1..65_535).cover?(port)

      port
    end
  end
end
