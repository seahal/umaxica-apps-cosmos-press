# frozen_string_literal: true

require "test_helper"

class PublicMethodContractValuesTest < ActiveSupport::TestCase
  class AbstractTaxonomyAssignment < ApplicationRecord
    self.abstract_class = true
    include PublishingFamilyTaxonomyAssignment
  end

  test "taxonomy assignment base class requires its concrete vocabulary kind" do
    error = assert_raises(NotImplementedError) { AbstractTaxonomyAssignment.expected_kind }

    assert_match(/must declare expected_kind/, error.message)
  end

  test "taxonomy assignment structural kinds follow their declared vocabulary kind" do
    single = Publishing::Info::App::RevisionSingleTaxonomyAssignment.new(
      vocabulary_kind: Publishing::TaxonomyKind::SINGLE_HIERARCHICAL,
    )
    multiple = Publishing::Info::App::RevisionMultipleTaxonomyAssignment.new(
      vocabulary_kind: Publishing::TaxonomyKind::MULTIPLE_ORDERED_FLAT,
    )

    assert_equal Publishing::TaxonomyKind::SINGLE_HIERARCHICAL, single.structural_kind.key
    assert_equal Publishing::TaxonomyKind::MULTIPLE_ORDERED_FLAT, multiple.structural_kind.key
    cell_assignments = Publishing::ContentFamilies::CELL_BY_ENTRY.values
    single_assignments =
      cell_assignments.flat_map do |cell|
        [cell.fetch(:revision_single), cell.fetch(:version_single)]
      end
    multiple_assignments =
      cell_assignments.flat_map do |cell|
        [cell.fetch(:revision_multiple), cell.fetch(:version_multiple)]
      end

    assert_equal Array.new(24, Publishing::TaxonomyKind::SINGLE_HIERARCHICAL),
                 single_assignments.map(&:expected_kind)

    assert_equal Array.new(24, Publishing::TaxonomyKind::MULTIPLE_ORDERED_FLAT),
                 multiple_assignments.map(&:expected_kind)
    taxonomy_term = Publishing::Info::App::TaxonomyTerm.new

    assert_equal Publishing::ContentFamilies::CELL_BY_TAXONOMY_TERM.fetch(taxonomy_term.class),
                 Publishing::ContentFamilies.cell_for_taxonomy_term(taxonomy_term)
    assert_raises(ArgumentError) { Publishing::ContentFamilies.cell_for_taxonomy_term(Object.new) }
  end

  test "publication and taxonomy term expose their terminal and root states" do
    publication = Publishing::Info::App::Publication.new(terminated_at: Time.zone.parse("2026-11-12 12:00:00"))
    taxonomy_root = Publishing::Info::App::TaxonomyTerm.new(parent_id: nil)
    taxonomy_child = Publishing::Info::App::TaxonomyTerm.new(parent_id: 1)

    assert_predicate publication, :terminated?
    assert_predicate taxonomy_root, :root?
    assert_not_predicate taxonomy_child, :root?
  end

  test "successful archive result retains the archived entry" do
    entry = Publishing::Info::App::Entry.new
    result = PublishingArchiveEntryResult.success(entry)

    assert_predicate result, :ok?
    assert_same entry, result.entry
    assert_empty result.errors
  end

  test "publishing revision and version classes map back to their own entry family" do
    revision = Publishing::Info::App::EntryRevision.new
    version = Publishing::Info::App::EntryVersion.new

    assert_equal Publishing::Info::App::Entry, Publishing::ContentFamilies.entry_class_for_revision(revision)
    assert_equal Publishing::Info::App::Entry, Publishing::ContentFamilies.entry_class_for_version(version)
  end

  test "identifier inventory result serializes its stable public shape" do
    connections = [{ name: "primary", tables: [] }]
    result = IdentifierContractInventoryQuery::Result.new(
      version: IdentifierContractInventoryQuery::VERSION,
      generated_at: "2026-11-06T00:00:00Z",
      connections: connections,
    )

    assert_equal(
      { version: IdentifierContractInventoryQuery::VERSION, generated_at: "2026-11-06T00:00:00Z", connections: },
      result.to_h,
    )
    assert_equal result.to_h, JSON.parse(result.to_json, symbolize_names: true)
  end

  test "published entries query returns an empty relation when locale is absent" do
    query = PublishingPublishedEntriesQuery.new(entry_class: Publishing::Info::App::Entry, locale: " ")

    assert_empty query.call
    assert_empty PublishingPublishedEntriesQuery.call(entry_class: Publishing::Info::App::Entry, locale: " ")
  end
end
