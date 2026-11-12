# frozen_string_literal: true

# The single trusted execution role of this process (docs/security/role-secret-isolation.md).
#
# A role decides which controllers this process serves and which private signing keys it requires.
# It is read once from the process environment at boot and is never derived from request input
# (Host, `ri`, token claims). An unknown role aborts boot.
#
# A role does not select credentials or a database login: every process reads the Rails-standard
# config/credentials/<env>.yml.enc and the same database.yml (user decision 2026-10-19,
# adr/runtime-secret-isolation-deferred.md).
module RuntimeRole
  # The development process serves the currently owned surfaces together; production RP and
  # publishing processes use their dedicated roles.
  SHARED = "shared"

  # The Edit browser RP uses only its own client assertion key and local session cell.
  RP_ROLES = %w(rp-edit-org-ww).freeze
  DOMAIN_ROLES = %w(domain-publishing).freeze

  ALL = ([SHARED] + RP_ROLES + DOMAIN_ROLES).freeze

  class UnknownRole < ArgumentError; end

  module_function

  # Required: a process without an explicit role must not boot (no silent default to `shared`).
  def current
    name = ENV.fetch("UMAXICA_RUNTIME_ROLE")
    raise UnknownRole, "unknown runtime role: #{name.inspect}" unless ALL.include?(name)

    name
  end

  def shared?(name = current)
    name == SHARED
  end

  # The cell store connection of the Edit RP role.
  def cell_connection(name = current)
    raise UnknownRole, "#{name} is not an RP cell role" unless RP_ROLES.include?(name)

    name.delete_prefix("rp-").split("-").first(2).unshift("rp").join("_")
  end

  # Private signing material an RP process may hold: its own private_key_jwt client key and its
  # surface's Jump return-token key.
  def rp_private_env_names(name = current)
    raise UnknownRole, "#{name} is not an RP cell role" unless RP_ROLES.include?(name)

    family, realm, region = name.delete_prefix("rp-").split("-")
    client_namespace = "#{family}_#{realm}_#{region}"
    surface_namespace = "#{family}_#{realm}"
    [
      "OIDC_CLIENT_#{client_namespace.upcase}_PRIVATE_KEY",
      "JWT_#{surface_namespace.upcase}_PRIVATE_KEY",
    ].freeze
  end

  BROWSER_ADMISSION_STATES = %w(open closed).freeze
  # The RP serves protocol closure receivers and process health before browser admission opens.
  CLOSED_CELL_PATHS = %r{/(oidc/closures|health|healths|revisions)\z}

  # Required in the Edit RP process, never derived from a request. The cell starts closed until
  # deployment enables browser admission.
  def rp_browser_admission_open?
    state = ENV.fetch("UMAXICA_RP_BROWSER_ADMISSION")
    raise UnknownRole, "UMAXICA_RP_BROWSER_ADMISSION must be open or closed" unless
      BROWSER_ADMISSION_STATES.include?(state)

    state == "open"
  end

  class UnownedRoute < ArgumentError; end

  # Routes shared by the owned surfaces.
  ANY_ROLE = "*"

  CONTENT_FAMILIES = %w(docs help info news).freeze

  # The single role allowed to serve a routed controller, or ANY_ROLE. An unclassified controller
  # raises: a new route must be assigned an owner explicitly, never inherit one by accident.
  def route_owner(controller_path)
    family, _, rest = controller_path.to_s.split("/", 3)
    case family
    when "edit"
      return "domain-publishing" if rest.to_s == "api/v0/publishing" || rest.to_s.start_with?("api/v0/publishing/")

      "rp-edit-org-ww"
    when "unknown_hosts" then ANY_ROLE
    when *CONTENT_FAMILIES then "domain-publishing"
    else raise UnownedRoute, "no runtime role owns #{controller_path.inspect}"
    end
  end

  # True when this process may serve an owned controller. A shared process can serve every
  # currently assigned route, but an unowned controller remains denied in every role.
  def serves?(controller_path, name = current)
    owner = route_owner(controller_path)
    return true if shared?(name)
    return false unless owner == ANY_ROLE || owner == name
    return true unless RP_ROLES.include?(name)

    rp_browser_admission_open? || CLOSED_CELL_PATHS.match?(controller_path)
  rescue UnownedRoute
    false
  end
end
