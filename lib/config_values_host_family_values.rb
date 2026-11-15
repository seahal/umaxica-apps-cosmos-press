# frozen_string_literal: true

module ConfigValues
  HostFamilyValues =
    Data.define(
      :sign_service,
      :sign_staff,
      :base_service,
      :base_corporate,
      :base_staff,
      :visa_service,
      :visa_staff,
      :docs_service,
      :docs_corporate,
      :docs_staff,
      :news_service,
      :news_corporate,
      :news_staff,
      :help_service,
      :help_corporate,
      :help_staff,
      :info_service,
      :info_corporate,
      :info_staff,
      :edit_staff,
    ) do
      def auth_service = sign_service

      def auth_staff = sign_staff

      def base_for_resource_type(resource_type)
        case resource_type.to_s
        when "client" then base_service
        when "operator", "staff" then base_staff
        else raise ArgumentError, "unsupported Base authority resource type"
        end
      end

      def docs_origins
        [docs_service, docs_corporate, docs_staff]
      end

      def news_origins
        [news_service, news_corporate, news_staff]
      end

      def info_origins
        [info_service, info_corporate, info_staff]
      end
    end
end

ConfigValuesHostFamilyValues = ConfigValues::HostFamilyValues

class << ConfigValues::HostFamilyValues
  public

  def build(env:, production:)
    ConfigValues::HostFamilyValues.new(**host_family_origins(env: env, production: production)).freeze
  end

  def host_family_origins(env:, production:)
    host_family_primary_origins(env: env, production: production).merge(
      host_family_secondary_origins(env: env, production: production),
    )
  end

  def host_family_primary_origins(env:, production:)
    {
      sign_service: origin(env, auth_key(env, "SERVICE"), production: production),
      sign_staff: origin(env, auth_key(env, "STAFF"), production: production),
      base_service: origin(env, base_key(env, "SERVICE"), production: production),
      base_corporate: origin(env, base_key(env, "CORPORATE"), production: production),
      base_staff: origin(env, base_key(env, "STAFF"), production: production),
      visa_service: origin(env, visa_key(env, "SERVICE"), production: production),
      visa_staff: origin(env, visa_key(env, "STAFF"), production: production),
    }
  end

  def host_family_secondary_origins(env:, production:)
    {
      help_service: origin(env, help_key(env, "SERVICE"), production: production),
      help_corporate: origin(env, help_key(env, "CORPORATE"), production: production),
      help_staff: origin(env, help_key(env, "STAFF"), production: production),
      info_service: origin(env, info_key(env, "SERVICE"), production: production),
      info_corporate: origin(env, info_key(env, "CORPORATE"), production: production),
      info_staff: origin(env, info_key(env, "STAFF"), production: production),
    }.merge(host_family_content_origins(env: env, production: production))
      .merge(host_family_utility_origins(env: env, production: production))
  end

  def host_family_content_origins(env:, production:)
    {
      docs_service: origin(env, "PRIVATE_DOCS_SERVICE_URL", production: production),
      docs_corporate: origin(env, "PRIVATE_DOCS_CORPORATE_URL", production: production),
      docs_staff: origin(env, "PRIVATE_DOCS_STAFF_URL", production: production),
      news_service: origin(env, "PRIVATE_NEWS_SERVICE_URL", production: production),
      news_corporate: origin(env, "PRIVATE_NEWS_CORPORATE_URL", production: production),
      news_staff: origin(env, "PRIVATE_NEWS_STAFF_URL", production: production),
    }
  end

  def host_family_utility_origins(env:, production:)
    {
      edit_staff: origin(env, edit_key(env), production: production),
    }
  end

  # Resolves the ENV key for a base surface (service/corporate/staff).
  def base_key(env, surface)
    if env.key?("BASE_#{surface}_URL")
      "BASE_#{surface}_URL"
    else
      "PUBLIC_BASE_#{surface}_URL"
    end
  end

  # Help and Info origins use the private ingress in development. The old
  # unprefixed keys remain accepted when they are the configured input.
  def help_key(env, surface)
    private_key = "PRIVATE_HELP_#{surface}_URL"
    env.key?(private_key) ? private_key : "HELP_#{surface}_URL"
  end

  def info_key(env, surface)
    private_key = "PRIVATE_INFO_#{surface}_URL"
    env.key?(private_key) ? private_key : "INFO_#{surface}_URL"
  end

  # Resolves the Visa OP origin for a realm. Deployments may use the private
  # style key or the public style key; the former remains authoritative when
  # both are present, matching the existing Base contract.
  def visa_key(env, surface)
    if env.key?("VISA_#{surface}_URL")
      "VISA_#{surface}_URL"
    else
      "PUBLIC_VISA_#{surface}_URL"
    end
  end

  # Resolves the ENV key for an auth surface (service/corporate/staff).
  #
  # Deployments publish this family as PUBLIC_AUTH_*_URL. Selecting that key when
  # the legacy AUTH_*_URL input is absent keeps the CSP form-action allowlist aligned
  # with the deployed Auth origin, including outside RAILS_ENV=production.
  def auth_key(env, surface)
    if env.key?("AUTH_#{surface}_URL")
      "AUTH_#{surface}_URL"
    else
      "PUBLIC_AUTH_#{surface}_URL"
    end
  end

  def edit_key(env)
    env.key?("EDIT_STAFF_URL") ? "EDIT_STAFF_URL" : "PUBLIC_EDIT_STAFF_URL"
  end

  def origin(env, key, production:)
    raw = env.fetch(key)
    allow_localhost = !production
    uri = raw.to_s.match?(%r{\Ahttps?://}) ? raw : "https://#{raw}"
    ConfigValues.build(uri, allow_localhost: allow_localhost)
  rescue KeyError
    raise KeyError, "Missing required ENV key: #{key}"
  end

  private :host_family_origins, :host_family_primary_origins, :host_family_secondary_origins,
          :host_family_content_origins, :host_family_utility_origins, :edit_key,
          :help_key, :info_key, :visa_key
end
