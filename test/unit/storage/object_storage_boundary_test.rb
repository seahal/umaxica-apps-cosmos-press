# typed: false
# frozen_string_literal: true

require "test_helper"

class ObjectStorageBoundaryTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "registered boundaries match the attachment-owning domains" do
    assert_equal(%i(publishing), ObjectStorage::Boundary.keys)
  end

  test "an unregistered boundary raises and names the boundary" do
    assert_not(ObjectStorage::Boundary.registered?(:not_a_boundary))

    error = assert_raises(ArgumentError) { ObjectStorage::Boundary.bucket_variable(:not_a_boundary) }
    assert_match("not_a_boundary", error.message)
  end

  test "a registered boundary resolves to its own bucket variable" do
    original = ObjectStorage::Boundary::REGISTRY
    Kernel.silence_warnings { ObjectStorage::Boundary.const_set(:REGISTRY, { demo: "DEMO" }.freeze) }
    ENV["OBJECT_STORAGE_BUCKET_DEMO"] = "umaxica-demo"

    assert(ObjectStorage::Boundary.registered?(:demo))
    assert_equal("OBJECT_STORAGE_BUCKET_DEMO", ObjectStorage::Boundary.bucket_variable(:demo))
    assert_equal("umaxica-demo", ObjectStorage::Boundary.bucket(:demo))
  ensure
    Kernel.silence_warnings { ObjectStorage::Boundary.const_set(:REGISTRY, original) }
    ENV.delete("OBJECT_STORAGE_BUCKET_DEMO")
  end

  test "a registered boundary with no configured bucket raises" do
    original = ObjectStorage::Boundary::REGISTRY
    Kernel.silence_warnings { ObjectStorage::Boundary.const_set(:REGISTRY, { demo: "DEMO" }.freeze) }
    ENV.delete("OBJECT_STORAGE_BUCKET_DEMO")

    assert_raises(KeyError) { ObjectStorage::Boundary.bucket(:demo) }
  ensure
    Kernel.silence_warnings { ObjectStorage::Boundary.const_set(:REGISTRY, original) }
  end
end
