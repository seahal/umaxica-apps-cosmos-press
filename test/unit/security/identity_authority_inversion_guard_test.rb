# typed: false
# frozen_string_literal: true

require "test_helper"
# require "helpers/global_test_support"

class IdentityAuthorityInversionGuardTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "Edit RP routes do not expose OIDC provider endpoints" do
    source = file_content("config/routes/edit.rb")

    assert_source_excludes source, "resource :openid_configuration"
    assert_source_excludes source, "namespace :oauth"
    assert_source_excludes source, "resource :authorization"
    assert_source_excludes source, "resource :token"
    assert_source_excludes source, "resource :userinfo"
    assert_source_excludes source, "resource :introspection"
    assert_source_excludes source, "resource :refresh"
    assert_source_includes source, "resource :callback, only: :show"
    assert_source_includes source, "resources :closures, only: :create"
  end

  private

  def file_content(path)
    Rails.root.join(path).read
  end

  # These guards assert that a route is *declared*, not how the declaration happens to be
  # wrapped. Matching raw source made them fail whenever a formatter moved an argument to
  # the next line, which says nothing about the invariant being guarded. Collapse runs of
  # whitespace on both sides so the comparison is about the declaration itself.
  def normalize_source(text)
    text.gsub(/\s+/, " ").strip
  end

  def assert_source_includes(source, snippet, message = nil)
    assert_includes normalize_source(source), normalize_source(snippet), message
  end

  def assert_source_excludes(source, snippet, message = nil)
    assert_not_includes normalize_source(source), normalize_source(snippet), message
  end
end
