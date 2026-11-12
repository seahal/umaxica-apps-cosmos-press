# typed: false
# frozen_string_literal: true

require "test_helper"
# require "helpers/global_test_support"

module Concerns
  class ApplicationControllerCommonPatternsTest < ActiveSupport::TestCase
    self.fixture_table_names = []

    ALL_CONTROLLER_FILES = Dir.glob(Rails.root.join("app/controllers/**/application_controller.rb").to_s)
      .reject { |f| f.include?("/vendor/") }
      .reject { |f| f.end_with?("/controllers/application_controller.rb") }
      .sort
    CONTROLLER_FILES =
      ALL_CONTROLLER_FILES.index_with do |file|
        {
          content: File.read(file),
          name: file.gsub(Rails.root.join("app/controllers/").to_s, "")
            .gsub("/application_controller.rb", "")
            .gsub("/", "::")
            .gsub("_", " ")
            .split.map(&:capitalize).join("::"),
          path_name: file.gsub(Rails.root.join("app/controllers/").to_s, "")
            .gsub("/application_controller.rb", "")
            .gsub("/", "::"),
        }
      end

    test "all application controllers include RateLimit" do
      CONTROLLER_FILES.each_value do |controller|
        content = controller[:content]
        controller_name = controller[:name]

        assert_includes content, "RateLimit",
                        "#{controller_name} should include RateLimit"
      end
    end

    test "application controllers do not register removed default rate limit callback" do
      CONTROLLER_FILES.each_value do |controller|
        content = controller[:content]
        controller_name = controller[:path_name]

        assert_not_includes content, "before_action :check_default_rate_limit",
                            "#{controller_name} should not use removed default rate limit callback"
      end
    end

    test "Edit org authenticates locally and authorizes through the verified RP principal" do
      controller = CONTROLLER_FILES.values.find { |entry| entry[:path_name] == "edit::org" }

      assert_not_nil controller, "expected the retained Edit org application controller"
      %w(BrowserRpAuthentication BrowserRpSafeRequestRefresh BrowserRpUnsafeRequestRefresh
         ActionPolicy::Controller).each do |concern|
        assert_includes controller[:content], concern, "edit::org should include #{concern}"
      end
      assert_includes controller[:content], "authorize :user, through: :current_resource"
    end

    # The com realm was retired (WU-4); no application controller may reintroduce a visitor
    # credential boundary. This is the wedge guarding against its return.
    test "no application controller authenticates a visitor" do
      CONTROLLER_FILES.each_value do |controller|
        assert_not_includes controller[:content], "AuthenticationVisitor",
                            "#{controller[:path_name]} must not authenticate a visitor"
      end
    end

    test "application controllers with OIDC include OidcSsoInitiator" do
      CONTROLLER_FILES.each_value do |controller|
        content = controller[:content]
        controller_name = controller[:path_name]

        if content.include?("oidc_client_id")
          assert_includes content, "OidcSsoInitiator",
                          "#{controller_name} with oidc_client_id should include OidcSsoInitiator"
        end
      end
    end

    # Controllers that run the full authenticated request lifecycle are marked by
    # enforce_access_policy!. dev/net/palm bare bases do not run it and are excluded.
    def lifecycle_controllers
      CONTROLLER_FILES.values.select do |controller|
        controller[:content].include?("enforce_access_policy!")
      end
    end

    # Wedge: every full-lifecycle surface controller must reflect the request locale.
    # Regression guard against the com/org surfaces silently dropping set_locale again.

    # Wedge: the retired session-limit placeholder must not reintroduce a controller guard.
    test "lifecycle application controllers do not register the retired restricted-session guard" do
      lifecycle_controllers.each do |controller|
        content = controller[:content]
        controller_name = controller[:path_name]

        assert_not_includes content, "RestrictedSessionGuard",
                            "#{controller_name} reintroduced the retired restricted-session guard"
        assert_no_match(
          /before_action :enforce_restricted_session_guard!$/,
          content,
          "#{controller_name} reintroduced the retired restricted-session callback",
        )
      end
    end

    # Edit is the retained application surface with a full actor lifecycle; content surfaces render
    # published documents and do not carry browser preference state.
  end
end
