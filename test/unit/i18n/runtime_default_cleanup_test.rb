# typed: false
# frozen_string_literal: true

require "test_helper"
# require "helpers/global_test_support"

class I18nRuntimeDefaultCleanupTest < ActiveSupport::TestCase
  # meta.default_title is intentionally absent: the brand and its TLD edition are
  # a locale-independent contract carried by the layouts' meta-tags site title, so
  # only page-specific titles are translated.
  test "retained Edit error responses have translations in ja and en" do
    [:ja, :en].each do |locale|
      assert_predicate I18n.t("sign.org.verification.step_up_unavailable", locale:, fallback: false, raise: true),
                       :present?
      assert_predicate I18n.t("errors.invalid_authenticity_token", locale:, fallback: false, raise: true),
                       :present?
    end
  end
end
