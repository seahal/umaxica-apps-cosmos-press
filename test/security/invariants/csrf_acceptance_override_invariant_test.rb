# typed: false
# frozen_string_literal: true

require "test_helper"

# D-80: request forgery protection is the installed Rails implementation. No class may redefine
# what counts as a verified request or an acceptable Origin, and forgery protection is skipped only
# by the CSP report endpoint, which browsers post without credentials or a token.
class CsrfAcceptanceOverrideInvariantTest < ActiveSupport::TestCase
  SCANNED = %w(app lib).freeze
  ACCEPTANCE_OVERRIDE =
    /^\s*def\s+(?:self\.)?(valid_request_origin\?|verified_request\?|verified_request_for_forgery_protection\?)/
  SKIP = Regexp.union(
    /skip_forgery_protection/,
    /skip_before_action\s+:verify_authenticity_token/,
    /protect_from_forgery\s+with:\s+:null_session/,
  )
  PERMITTED_SKIPS = { "app/controllers/concerns/csp_violation_report.rb" => 1 }.freeze

  test "no class redefines verified-request or Origin acceptance" do
    offenders =
      begin
        fv5011 = ACCEPTANCE_OVERRIDE
        begin
          SCANNED.flat_map { |fv5013|
            Rails.root.glob("#{fv5013}/**/*.rb")
          }
            .map { |fv5012| fv5012.relative_path_from(Rails.root).to_s }
        end.flat_map do |fv5002|
          Rails.root.join(fv5002).each_line.with_index(1).filter_map do |fv5009, fv5010|
            "#{fv5002}:#{fv5010}:#{fv5009.strip}" if fv5009.match?(fv5011) && !fv5009.lstrip.start_with?("#")
          end
        end
      end

    assert_empty offenders, "custom CSRF acceptance must not exist:\n#{offenders.join("\n")}"
  end

  test "forgery protection is skipped only by the CSP report endpoint" do
    counts = begin
      fv5006 = SKIP
      begin
        SCANNED.flat_map { |fv5008| Rails.root.glob("#{fv5008}/**/*.rb") }
          .map { |fv5007| fv5007.relative_path_from(Rails.root).to_s }
      end.flat_map do |fv5000|
        Rails.root.join(fv5000).each_line.with_index(1).filter_map do |fv5004, fv5005|
          "#{fv5000}:#{fv5005}:#{fv5004.strip}" if fv5004.match?(fv5006) && !fv5004.lstrip.start_with?("#")
        end
      end
    end.map { |entry| entry.split(":").first }.tally

    assert_equal PERMITTED_SKIPS, counts
  end

  test "the scan covers both application and library Ruby sources" do
    paths =
      SCANNED.flat_map { |root| Rails.root.glob("#{root}/**/*.rb") }
        .map { |path| path.relative_path_from(Rails.root).to_s }

    assert_includes paths, "app/controllers/edit/org/application_controller.rb"
    assert_includes paths, "lib/observability_span_scrubber.rb"
    assert_equal Rails.root.glob("{app,lib}/**/*.rb").size, paths.size
  end
end
