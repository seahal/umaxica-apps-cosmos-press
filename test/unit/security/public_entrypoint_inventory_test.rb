# typed: false
# frozen_string_literal: true

require "test_helper"

module Security
  class PublicEntrypointInventoryTest < ActiveSupport::TestCase
    self.fixture_table_names = []

    APP_CONTROLLER_PREFIXES = %w(edit docs help info news).freeze
    APPLICATION_CLASS_PREFIXES = %w(Edit:: Docs:: Help:: Info:: News::).freeze

    PUBLIC_MODES = %i(bare open guest).freeze
    PRIVATE_MODES = %i(private deny_all).freeze

    DOCUMENT_PATH = Rails.root.join("docs/security/public-entrypoints.md")
    DOCUMENTED_CATEGORY_IDS = %w(
      PUBLIC_ROOTS
      PUBLIC_HEALTH
      PUBLIC_REVISION
      PUBLIC_CSP_REPORTS
      PUBLIC_CONTENT_READ_APIS
      PUBLIC_EDIT_BROWSER_RP
      PUBLIC_EDIT_SIGN_OUT
      PUBLIC_EDIT_PUBLISHING_API
    ).freeze

    RouteEntry = Struct.new(:verb, :path, :controller_path, :action, :controller_class, :mode, keyword_init: true)

    test "public entrypoint documentation names every enforced category" do
      content = File.read(DOCUMENT_PATH)

      DOCUMENTED_CATEGORY_IDS.each do |category_id|
        assert_includes content, "`#{category_id}`"
      end
    end

    test "application routes resolve to locally declared authentication modes" do
      missing =
        application_route_entries.filter_map do |entry|
          next if local_authentication_declaration?(entry.controller_class)

          "#{entry.verb} #{entry.path} => #{entry.controller_path}##{entry.action}"
        end

      assert_empty missing, "Application routes must declare authentication mode locally:\n#{missing.join("\n")}"
    end

    test "public application routes are covered by the documented public categories" do
      undocumented =
        application_route_entries.filter_map do |entry|
          next unless PUBLIC_MODES.include?(entry.mode)
          next if documented_public_category(entry)

          "#{entry.mode} #{entry.verb} #{entry.path} => #{entry.controller_path}##{entry.action}"
        end

      assert_empty undocumented, "Public routes need a documented category:\n#{undocumented.join("\n")}"
    end

    test "private and deny-all routes are not public entrypoints" do
      wrongly_public =
        application_route_entries.filter_map do |entry|
          next unless PRIVATE_MODES.include?(entry.mode)
          next unless documented_public_category(entry)

          "#{entry.mode} #{entry.verb} #{entry.path} => #{entry.controller_path}##{entry.action}"
        end

      assert_empty wrongly_public, "Private routes must not match public categories:\n#{wrongly_public.join("\n")}"
    end

    private

    def application_route_entries
      Rails.application.routes.routes.filter_map do |route|
        controller_path = route.defaults[:controller].to_s
        action = route.defaults[:action].to_s
        next if controller_path.blank? || action.blank?
        next unless application_controller_path?(controller_path)

        controller_class = "#{controller_path.camelize}Controller".safe_constantize
        mode = authentication_mode(controller_class, action)

        RouteEntry.new(
          verb: route.verb.presence || "ANY",
          path: route.path.spec.to_s.sub(/\(\.:format\)\z/, ""),
          controller_path: controller_path,
          action: action,
          controller_class: controller_class,
          mode: mode,
        )
      end
    end

    def application_controller_path?(controller_path)
      APP_CONTROLLER_PREFIXES.any? { |prefix| controller_path.start_with?("#{prefix}/") }
    end

    def authentication_mode(controller_class, action)
      flunk("Missing controller class for application route") if controller_class.blank?
      flunk("Unexpected controller class #{controller_class.name}") unless
        application_controller_class?(controller_class)

      if controller_class.respond_to?(:authentication_mode_for)
        controller_class.authentication_mode_for(action)
      elsif controller_class.const_defined?(:AUTHENTICATION_MODE, false)
        controller_class.const_get(:AUTHENTICATION_MODE, false)
      else
        flunk("#{controller_class.name} does not expose authentication mode metadata")
      end
    end

    def application_controller_class?(controller_class)
      controller_class.name.start_with?(*APPLICATION_CLASS_PREFIXES)
    end

    def local_authentication_declaration?(controller_class)
      controller_class.const_defined?(:AUTHENTICATION_MODE, false) ||
        (controller_class.respond_to?(:local_authentication_mode_rules) &&
          controller_class.local_authentication_mode_rules.present?)
    end

    def documented_public_category(entry)
      return false unless PUBLIC_MODES.include?(entry.mode)

      public_root?(entry) || public_health?(entry) || public_revision?(entry) ||
        public_csp_report?(entry) || public_content_read_api?(entry) ||
        public_edit_browser_rp?(entry) || public_edit_sign_out?(entry) || public_edit_owner_api?(entry)
    end

    def public_root?(entry) = get?(entry) && entry.path == "/"

    def public_health?(entry)
      get?(entry) && (entry.path.start_with?("/health") || entry.path == "/api/v0/health.json")
    end

    def public_revision?(entry)
      get?(entry) && ["/revision", "/api/v0/revision.json"].include?(entry.path)
    end

    def public_csp_report?(entry) = post?(entry) && entry.path == "/csp-violation-report"

    def public_content_read_api?(entry)
      return false unless get?(entry)

      entry.controller_path.start_with?("docs/", "help/", "info/", "news/") &&
        entry.path.start_with?("/api/v0/entries")
    end

    def public_edit_browser_rp?(entry)
      entry.controller_path.start_with?("edit/org/") &&
        (entry.path == "/sign" || entry.path == "/sign/interruption" || entry.path.start_with?("/oidc/"))
    end

    def public_edit_sign_out?(entry)
      entry.controller_path.start_with?("edit/org/") && entry.path.start_with?("/sign/out")
    end

    def public_edit_owner_api?(entry)
      entry.controller_path.start_with?("edit/org/api/v0/publishing/") &&
        entry.path.start_with?("/api/v0/publishing/")
    end

    def get?(entry) = route_allows?(entry, "GET")

    def post?(entry) = route_allows?(entry, "POST")

    def route_allows?(entry, verb)
      entry.verb.split("|").include?(verb)
    end
  end
end
