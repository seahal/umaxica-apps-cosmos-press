# typed: false
# frozen_string_literal: true

require "test_helper"

module Security
  class AuthenticationModeInventoryTest < ActiveSupport::TestCase
    self.fixture_table_names = []

    test "Edit surface application controller defaults to deny_all" do
      assert_equal :deny_all, Edit::Org::ApplicationController.authentication_mode_for(:index)
    end

    test "controller files declare a local authentication mode" do
      missing =
        Rails.root.glob("app/controllers/**/*_controller.rb").filter_map do |path|
          controller_class = controller_class_for(path)
          next unless controller_class&.include?(BrowserRpAuthentication)

          relative_path = path.relative_path_from(Rails.root).to_s
          content = File.binread(path).encode("UTF-8", invalid: :replace, undef: :replace)
          relative_path unless content.match?(/\bAUTHENTICATION_MODE\s*=/)
        end

      assert_empty missing, "Controllers must declare local AUTHENTICATION_MODE:\n#{missing.join("\n")}"
    end

    test "controller files do not use legacy authentication posture DSL" do
      legacy =
        Rails.root.glob("app/controllers/**/*_controller.rb").filter_map do |path|
          relative_path = path.relative_path_from(Rails.root).to_s
          content = File.binread(path).encode("UTF-8", invalid: :replace, undef: :replace)
          matches = content.scan(/\b(?:deny_all!|public_strict!|auth_required!|guest_only!)/)
          "#{relative_path}: #{matches.uniq.join(", ")}" if matches.any?
        end

      assert_empty legacy, "Controllers must use AUTHENTICATION_MODE instead of legacy DSL:\n#{legacy.join("\n")}"
    end

    test "bare controllers inherit directly from action controller base" do
      violations =
        Rails.root.glob("app/controllers/**/bare_controller.rb").filter_map do |path|
          relative_path = path.relative_path_from(Rails.root).to_s
          content = File.binread(path).encode("UTF-8", invalid: :replace, undef: :replace)
          relative_path unless content.match?(/class\s+BareController\s+<\s+ActionController::Base\b/)
        end

      assert_empty violations,
                   "Bare controllers must inherit ActionController::Base directly:\n#{violations.join("\n")}"
    end

    test "routes resolve to controllers with local authentication mode declarations" do
      missing =
        Rails.application.routes.routes.filter_map do |route|
          controller_name = route.defaults[:controller]
          action_name = route.defaults[:action]
          next if controller_name.blank? || action_name.blank?

          controller_class = "#{controller_name.camelize}Controller".safe_constantize
          next if controller_class.blank?
          next unless controller_class.name.start_with?("Edit::")
          next unless controller_class.include?(BrowserRpAuthentication)
          next if controller_class.const_defined?(:AUTHENTICATION_MODE, false)
          next if controller_class.respond_to?(:local_authentication_mode_rules) &&
            controller_class.local_authentication_mode_rules.present?

          "#{route.verb.presence || "ANY"} #{route.path.spec} => #{controller_class.name}##{action_name}"
        end

      assert_empty missing, "Routes must not rely on inherited authentication mode:\n#{missing.join("\n")}"
    end

    private

    def controller_class_for(path)
      relative = path.relative_path_from(Rails.root.join("app/controllers")).to_s.delete_suffix(".rb")
      "#{relative.camelize}Controller".safe_constantize
    end
  end
end
