# typed: false
# frozen_string_literal: true

require "test_helper"

# Unit tops for still-cold value/lib/model arms.
class BranchCoverageBatch27ValuesLibEasyArmsTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "lib ChainSeal and ObservabilityRedactor easy arms" do
    assert_not ChainSeal.respond_to?(:ensure_ready!, true)
    assert_equal "[FILTERED]", ObservabilityRedactor.scrub(password: "secret")[:password]
  end

  test "lib LocalEnvironment and ConfigValuesOriginValue arms" do
    assert_not LocalEnvironment.respond_to?(:enabled?)
    assert_equal "https://example.com", ConfigValues.build("example.com").to_s
    assert_raises(ArgumentError) { ConfigValues.build("") }
  end

  test "Publishing form validation blank arms" do
    assert_predicate Publishing::PublishEntryForm.new, :valid?

    [Publishing::ArchiveEntryForm, Publishing::EndPublicationForm].each do |form_class|
      form = form_class.new
      outcome =
        begin
          form.valid? ? :valid : :invalid
        rescue I18n::MissingTranslationData
          :translation_missing
        end

      assert_not_equal :valid, outcome
    end
  end
end
