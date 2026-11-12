# frozen_string_literal: true

require "test_helper"

module Publishing
  class ArchiveAndEndFormTest < ActiveSupport::TestCase
    test "archive and publication-ending forms report their required reasons" do
      archive = ArchiveEntryForm.new(reason: " ")
      end_publication = EndPublicationForm.new(reason: " ")

      assert_not_predicate archive, :valid?
      assert_equal({ reason: "can't be blank" }, archive.message_hash)
      assert_not_predicate end_publication, :valid?
      assert_equal({ reason: "can't be blank" }, end_publication.message_hash)
    end

    test "valid reasons leave their forms without field errors" do
      assert_predicate ArchiveEntryForm.new(reason: "superseded"), :valid?
      assert_empty EndPublicationForm.new(reason: "superseded").message_hash
    end
  end
end
