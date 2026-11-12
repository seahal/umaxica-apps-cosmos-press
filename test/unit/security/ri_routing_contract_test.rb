# frozen_string_literal: true

require "test_helper"

class RiRoutingContractTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  CONTENT_TARGETS = %w(
    docs/app docs/com docs/org help/app help/com help/org
    info/app info/com info/org news/app news/com news/org
  ).freeze

  test "controller ownership remains limited to Edit and the twelve public content cells" do
    targets = Rails.root.glob("app/controllers/**/*.rb").filter_map do |path|
      parts = path.relative_path_from(Rails.root.join("app/controllers")).each_filename.to_a
      next if parts.length < 3 || parts.first == "concerns"

      parts.first(2).join("/")
    end.uniq.sort

    assert_equal (CONTENT_TARGETS + ["edit/org"]).sort, targets
  end

  test "controllers cannot restore unavailable Governance preference hydration or region defaults" do
    offenders =
      Rails.root.glob("app/controllers/**/*.rb").flat_map do |path|
        path.readlines.each_with_index.filter_map do |line, index|
          next if line.lstrip.start_with?("#")
          next unless line.match?(/\b(?:PreferenceGlobal|set_region|set_timezone)\b/)

          "#{path.relative_path_from(Rails.root)}:#{index + 1}"
        end
      end

    assert_empty offenders
  end

  test "public content locale ownership remains with the published content renderer" do
    CONTENT_TARGETS.each do |target|
      controller = "#{target.camelize}::Api::V0::EntriesController".constantize

      assert_includes controller.ancestors, PublishingContentRendering, target
      assert_not_includes controller._process_action_callbacks.map(&:filter), :set_region, target
    end
  end
end
