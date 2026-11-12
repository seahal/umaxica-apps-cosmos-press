# typed: false
# frozen_string_literal: true

require "minitest/autorun"
require "active_support"
require "active_support/test_case"
require "tmpdir"
require_relative "../../lib/architecture_baseline"

# Ratchet for the Umaxica architecture cops.
#
# `.rubocop_todo.yml` keeps `bin/rubocop` green by excluding files that are already in debt, which
# alone would let a new violation slip into one of those files unnoticed. This test measures the
# repository with the excludes ignored and compares against the recorded per-file counts, so a debt
# file may only improve. Regenerate both artifacts with `bin/rails architecture:baseline`.
class ArchitectureBaselineTest < ActiveSupport::TestCase
  def test_no_file_exceeds_its_recorded_architecture_debt
    measured = ArchitectureBaseline.measure
    recorded = ArchitectureBaseline.recorded

    ArchitectureBaseline::COPS.each do |cop|
      recorded_files = recorded.fetch(cop)

      measured.fetch(cop).each do |path, count|
        allowed = recorded_files.fetch(path, 0)

        assert_operator count, :<=, allowed,
                        "#{path} has #{count} #{cop} offenses but the baseline allows #{allowed}. " \
                        "Fix the new violation; do not regenerate the baseline to hide it."
      end
    end
  end

  def test_baseline_and_rubocop_todo_describe_the_same_files
    recorded = ArchitectureBaseline.recorded
    todo = YAML.load_file(ArchitectureBaseline::TODO_PATH, aliases: false)

    ArchitectureBaseline::COPS.each do |cop|
      assert_equal recorded.fetch(cop).keys.sort, todo.fetch(cop).fetch("Exclude").sort, cop
    end
  end

  def test_baseline_does_not_list_resolved_files
    measured = ArchitectureBaseline.measure

    ArchitectureBaseline::COPS.each do |cop|
      stale = ArchitectureBaseline.recorded.fetch(cop).keys - measured.fetch(cop).keys

      assert_empty stale,
                   "#{cop} baseline lists files with no remaining offenses. " \
                   "Run bin/rails architecture:baseline to drop them."
    end
  end

  def test_write_updates_both_generated_artifacts_in_name_order
    Dir.mktmpdir("architecture-baseline-test") do |directory|
      counts_path = Pathname.new(directory).join("architecture_baseline.yml")
      todo_path = Pathname.new(directory).join("rubocop_todo.yml")
      counts = {
        "Umaxica/NoConcernInclusionHooks" => { "z.rb" => 1, "a.rb" => 2 },
        "Umaxica/ExplicitMethodVisibility" => {},
      }

      with_output_paths(counts_path, todo_path) { ArchitectureBaseline.write(counts) }

      assert_equal(
        ArchitectureBaseline::HEADER + {
          "Umaxica/NoConcernInclusionHooks" => { "a.rb" => 2, "z.rb" => 1 },
          "Umaxica/ExplicitMethodVisibility" => {},
        }.to_yaml,
        counts_path.read,
      )
      assert_includes todo_path.read, "    - \"a.rb\"\n    - \"z.rb\"\n"
    end
  end

  private

  # `ArchitectureBaseline.write` intentionally targets repository artifacts; redirecting the two
  # path constants keeps this behavior test isolated from the shared worktree.
  def with_output_paths(counts_path, todo_path)
    original_counts_path = ArchitectureBaseline::COUNTS_PATH
    original_todo_path = ArchitectureBaseline::TODO_PATH
    ArchitectureBaseline.send(:remove_const, :COUNTS_PATH)
    ArchitectureBaseline.const_set(:COUNTS_PATH, counts_path)
    ArchitectureBaseline.send(:remove_const, :TODO_PATH)
    ArchitectureBaseline.const_set(:TODO_PATH, todo_path)
    yield
  ensure
    ArchitectureBaseline.send(:remove_const, :COUNTS_PATH)
    ArchitectureBaseline.const_set(:COUNTS_PATH, original_counts_path)
    ArchitectureBaseline.send(:remove_const, :TODO_PATH)
    ArchitectureBaseline.const_set(:TODO_PATH, original_todo_path)
  end
end
