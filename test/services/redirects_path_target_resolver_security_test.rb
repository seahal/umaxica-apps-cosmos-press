# typed: false
# frozen_string_literal: true

require "test_helper"

class RedirectsPathTargetResolverSecurityTest < ActiveSupport::TestCase
  test "rejects redirect fuzz payloads without issuing path-target tokens" do
    [
      "https://evil.example",
      "//evil.example",
      "https://app.example.com.evil.example/path",
      "https://evil.example/@app.example.com",
      "/%2f%2fevil.example",
      "/\\evil.example",
      "/%5c%5cevil.example",
      "/sign/out?return_to=https://evil.example",
      "/publishing/docs/app/entries?return_to=https://evil.example",
    ].each do |payload|
      result = RedirectsPathTargetResolver.call(payload, source: :security_fuzz)

      assert_not_predicate result, :ok?, payload
      assert_predicate result.unsafe_value_digest, :present?, payload
      assert_not_equal payload, result.unsafe_value_digest
    end
  end

  test "keeps internal organization paths syntactically internal for later authorization gates" do
    [
      "/org/123/settings",
      "/org/999/settings",
    ].each do |payload|
      result = RedirectsPathTargetResolver.call(payload, source: :security_fuzz)

      assert_predicate result, :ok?, payload
      assert_equal payload, result.value
    end
  end

  test "rejects path targets without a rooted path and rejects fragments or malformed URI syntax" do
    [
      ["?next=one", "blank_path"],
      ["dashboard", "relative_path"],
      ["/dashboard#section", "fragment"],
      ["/[", "invalid_uri"],
    ].each do |value, expected_reason|
      result = RedirectsPathTargetResolver.call(value, source: :security_boundary)

      assert_not_predicate result, :ok?, value
      assert_equal expected_reason, result.failure_reason, value
    end
  end
end
