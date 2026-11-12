# frozen_string_literal: true

require "test_helper"

class TaxonomyUniquenessExceptionContractTest < ActiveSupport::TestCase
  FAMILIES = [
    [Publishing::Docs::App::Vocabulary, Publishing::Docs::App::TaxonomyTerm],
    [Publishing::Docs::Com::Vocabulary, Publishing::Docs::Com::TaxonomyTerm],
    [Publishing::Docs::Org::Vocabulary, Publishing::Docs::Org::TaxonomyTerm],
    [Publishing::Help::App::Vocabulary, Publishing::Help::App::TaxonomyTerm],
    [Publishing::Help::Com::Vocabulary, Publishing::Help::Com::TaxonomyTerm],
    [Publishing::Help::Org::Vocabulary, Publishing::Help::Org::TaxonomyTerm],
    [Publishing::Info::App::Vocabulary, Publishing::Info::App::TaxonomyTerm],
    [Publishing::Info::Com::Vocabulary, Publishing::Info::Com::TaxonomyTerm],
    [Publishing::Info::Org::Vocabulary, Publishing::Info::Org::TaxonomyTerm],
    [Publishing::News::App::Vocabulary, Publishing::News::App::TaxonomyTerm],
    [Publishing::News::Com::Vocabulary, Publishing::News::Com::TaxonomyTerm],
    [Publishing::News::Org::Vocabulary, Publishing::News::Org::TaxonomyTerm],
  ].freeze

  FAMILIES.each do |vocabulary_class, term_class|
    test "#{term_class.name} preflights slug conflicts while SQL retains both unique constraints" do
      vocabulary = vocabulary_class.create!(
        key: "exception_contract", kind: Publishing::TaxonomyKind::SINGLE_HIERARCHICAL,
        internal_name: "Contract",
      )
      attributes = { vocabulary: vocabulary,
                     vocabulary_kind: vocabulary.kind,
                     locale: "ja",
                     name: "Root",
                     slug: "first-root",
                     depth: 0,
                     position: 0, }
      first = term_class.create!(attributes)
      [0, 1].each do |position|
        assert_raises(ActiveRecord::RecordInvalid) do
          term_class.transaction(requires_new: true) { term_class.create!(attributes.merge(position: position)) }
        end
        error =
          assert_raises(ActiveRecord::RecordNotUnique) do
            term_class.transaction(requires_new: true) do
              term_class.insert_all!(
                [first.attributes.except("id").merge(
                  "public_id" => "z" * 21,
                  "position" => position,
                )],
              )
            end
          end
        assert_instance_of PG::UniqueViolation, error.cause
        assert_equal "first-root", first.reload.slug
      end
    end

    test "#{term_class.name} database treats NULL parents as the same sibling scope" do
      vocabulary = vocabulary_class.create!(
        key: "position_contract", kind: Publishing::TaxonomyKind::SINGLE_HIERARCHICAL,
        internal_name: "Contract",
      )
      attributes = { vocabulary: vocabulary,
                     vocabulary_kind: vocabulary.kind,
                     locale: "ja",
                     name: "Root",
                     depth: 0,
                     position: 0, }
      first = term_class.create!(attributes.merge(slug: "first-root"))

      assert_nil first.parent_id
      error =
        assert_raises(ActiveRecord::RecordNotUnique) do
          term_class.transaction(requires_new: true) do
            term_class.new(attributes.merge(slug: "second-root")).save!(validate: false)
          end
        end
      assert_instance_of PG::UniqueViolation, error.cause
      alternate_locale = term_class.create!(attributes.merge(slug: "first-root", locale: "en"))
      second_root = term_class.create!(attributes.merge(slug: "second-root", position: 1))
      first_child = term_class.create!(attributes.merge(slug: "first-child", parent: first, depth: 1))
      second_child = term_class.create!(attributes.merge(slug: "second-child", parent: second_root, depth: 1))

      assert_equal "en", alternate_locale.reload.locale
      assert_equal 0, first_child.reload.position
      assert_equal 0, second_child.reload.position
      assert_not_equal first_child.parent_id, second_child.parent_id
    end
  end
end
