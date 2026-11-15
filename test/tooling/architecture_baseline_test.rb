# typed: false
# frozen_string_literal: true

require "minitest/autorun"
require "active_support"
require "active_support/test_case"
require "tmpdir"
require_relative "../../lib/architecture_baseline"

# Ratchet for the Umaxica architecture cops.
#
# This test measures the repository and compares it with the per-file ratchet. RuboCop itself has
# no architecture-cop exclusions, and a file may only improve. Regenerate the count artifact with
# `bin/rails architecture:baseline` only after reducing existing debt.
class ArchitectureBaselineTest < ActiveSupport::TestCase
  def test_no_file_exceeds_its_recorded_architecture_debt
    measured = ArchitectureBaseline.measure
    recorded = ArchitectureBaseline.recorded

    ArchitectureBaseline::COPS.each do |cop|
      recorded_files = recorded.fetch(cop)

      assert_empty measured.fetch(cop), "#{cop} must report zero offenses"

      measured.fetch(cop).each do |path, count|
        allowed = recorded_files.fetch(path, 0)

        assert_operator count, :<=, allowed,
                        "#{path} has #{count} #{cop} offenses but the baseline allows #{allowed}. " \
                        "Fix the new violation; do not regenerate the baseline to hide it."
      end
    end
  end

  def test_rubocop_does_not_load_or_keep_an_architecture_suppression_file
    config = ArchitectureBaseline::ROOT.join(".rubocop.yml").read

    assert_not_includes config, ".rubocop_todo.yml"
    refute_path_exists ArchitectureBaseline::ROOT.join(".rubocop_todo.yml")
  end

  def test_baseline_does_not_list_resolved_files
    measured = ArchitectureBaseline.measure

    ArchitectureBaseline::COPS.each do |cop|
      recorded_files = ArchitectureBaseline.recorded.fetch(cop)

      assert_empty recorded_files, "#{cop} must have no recorded offenses"
      stale = recorded_files.keys - measured.fetch(cop).keys

      assert_empty stale,
                   "#{cop} baseline lists files with no remaining offenses. " \
                   "Run bin/rails architecture:baseline to drop them."
    end
  end

  def test_write_updates_the_generated_artifact_in_name_order
    Dir.mktmpdir("architecture-baseline-test") do |directory|
      counts_path = Pathname.new(directory).join("architecture_baseline.yml")
      counts = {
        "Umaxica/NoConcernInclusionHooks" => { "z.rb" => 1, "a.rb" => 2 },
        "Umaxica/ExplicitMethodVisibility" => {},
      }

      with_output_path(counts_path) { ArchitectureBaseline.write(counts) }

      assert_equal(
        ArchitectureBaseline::HEADER + {
          "Umaxica/NoConcernInclusionHooks" => { "a.rb" => 2, "z.rb" => 1 },
          "Umaxica/ExplicitMethodVisibility" => {},
        }.to_yaml,
        counts_path.read,
      )
    end
  end

  private

  # `ArchitectureBaseline.write` intentionally targets repository artifacts; redirecting the two
  # path constants keeps this behavior test isolated from the shared worktree.
  def with_output_path(counts_path)
    original_counts_path = ArchitectureBaseline::COUNTS_PATH
    ArchitectureBaseline.send(:remove_const, :COUNTS_PATH)
    ArchitectureBaseline.const_set(:COUNTS_PATH, counts_path)
    yield
  ensure
    ArchitectureBaseline.send(:remove_const, :COUNTS_PATH)
    ArchitectureBaseline.const_set(:COUNTS_PATH, original_counts_path)
  end
end
