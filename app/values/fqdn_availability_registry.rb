# typed: false
# frozen_string_literal: true

# The explicit allowlist of fully qualified domain names this Rails application serves, and the
# availability slot each one belongs to.
#
# The kill switch in `FqdnAvailabilityGate` selects a Flipper feature from the *slot*, never from the
# `Host` header. A header that does not appear here resolves to nil and the gate fails closed, so an
# attacker cannot invent a feature name -- or reach a surface -- by sending an arbitrary `Host`.
#
# The hostname lists mirror the `constraints(host:)` declarations in `config/routes/*.rb` exactly:
# same boot-config slots, same environment variables, same literal development aliases.
# `Security::Invariants::FqdnAvailabilityRegistryInvariantTest` fails when the two drift apart.
#
module FqdnAvailabilityRegistry
  Slot = Data.define(:name, :hostnames)

  # Slot name => the hostnames that reach it. Values are resolved once per boot, because
  # `config/routes/*.rb` resolves the same sources once per boot when the routes are drawn.
  SLOT_SOURCES = {
    docs_service: ->(hosts) { [hosts.docs_service.host, "docs.jp.umaxica.app", "docs.app.localhost"] },
    docs_corporate: ->(hosts) { [hosts.docs_corporate.host, "docs.jp.umaxica.com", "docs.com.localhost"] },
    docs_staff: ->(hosts) { [hosts.docs_staff.host, "docs.jp.umaxica.org", "docs.org.localhost"] },
    news_service: ->(hosts) { [hosts.news_service.host, "news.jp.umaxica.app", "news.app.localhost"] },
    news_corporate: ->(hosts) { [hosts.news_corporate.host, "news.jp.umaxica.com", "news.com.localhost"] },
    news_staff: ->(hosts) { [hosts.news_staff.host, "news.jp.umaxica.org", "news.org.localhost"] },
    help_service: ->(hosts) { [hosts.help_service.host, "help.jp.umaxica.app", "help.app.localhost"] },
    help_corporate: ->(hosts) { [hosts.help_corporate.host, "help.jp.umaxica.com", "help.com.localhost"] },
    help_staff: ->(hosts) { [hosts.help_staff.host, "help.jp.umaxica.org", "help.org.localhost"] },
    info_service: ->(hosts) { [hosts.info_service.host, "info.app.localhost", "info.umaxica.app"] },
    info_corporate: ->(hosts) { [hosts.info_corporate.host, "info.com.localhost", "info.umaxica.com"] },
    info_staff: ->(hosts) { [hosts.info_staff.host, "info.org.localhost", "info.umaxica.org"] },
    edit_staff: lambda { |hosts|
      [hosts.edit_staff.host, ENV["PUBLIC_EDIT_STAFF_URL"], ENV["PRIVATE_EDIT_STAFF_URL"],
       "edit.umaxica.org", "edit.org.localhost",]
    },
    mission: lambda { |_hosts|
      ["mission-press.umaxica.dev", ENV["PRIVATE_MISSION_URL"], "mission.core.dev.localhost"]
    },
    flipper: lambda { |_hosts|
      ["flipper-press.umaxica.dev", ENV["PRIVATE_FLIPPER_URL"], "flipper.core.dev.localhost"]
    },
    blazer: lambda { |_hosts|
      ["blazer-press.umaxica.dev", ENV["PRIVATE_BLAZER_URL"], "blazer.core.dev.localhost"]
    },
    pghero: lambda { |_hosts|
      ["pghero-press.umaxica.dev", ENV["PRIVATE_PGHERO_URL"], "pghero.core.dev.localhost"]
    },
    coverband: lambda { |_hosts|
      ["coverband-press.umaxica.dev", ENV["PRIVATE_COVERBAND_URL"], "coverband.core.dev.localhost"]
    },
    swagger: lambda { |_hosts|
      ["swagger-press.umaxica.dev", ENV["PRIVATE_SWAGGER_URL"], "swagger.core.dev.localhost"]
    },
  }.freeze

  SLOT_NAMES = SLOT_SOURCES.keys.freeze

  FLAG_PREFIX = "fqdn_available_"

  module_function

  def flag_name_for(slot) = :"#{FLAG_PREFIX}#{slot}"

  def flag_names = SLOT_NAMES.map { |slot| flag_name_for(slot) }

  # @return [Symbol, nil] the slot the hostname belongs to, or nil when the hostname is not served.
  def slot_for(hostname)
    return nil if hostname.blank?

    index.fetch(normalize(hostname), nil)
  end

  def slots
    @slots ||= SLOT_SOURCES.map do |name, source|
      Slot.new(name: name, hostnames: hostnames_from(source))
    end.freeze
  end

  # hostname => slot. Built once per boot and frozen.
  def index
    @index ||= slots.each_with_object({}) do |slot, map|
      slot.hostnames.each do |hostname|
        claimed = map[hostname]

        if claimed && claimed != slot.name
          raise ArgumentError,
                "FQDN #{hostname} is claimed by both #{claimed} and #{slot.name}; " \
                "one hostname cannot have two availability switches"
        end

        map[hostname] = slot.name
      end
    end.freeze
  end

  def hostnames_from(source)
    hostnames =
      source.call(Rails.configuration.x.boot_config.fetch(:hosts)).compact_blank.map do |value|
        normalize(value)
      end
    hostnames.uniq!
    hostnames.freeze
  end

  def normalize(value) = value.to_s.strip.downcase
  private_class_method :hostnames_from
end
