# typed: false
# frozen_string_literal: true

require "test_helper"

class I18nDebugTest < ActiveSupport::TestCase
  test "retained Edit verification translations exist" do
    [:ja, :en].each do |locale|
      assert_predicate I18n.t("auth.step_up.challenge.title", locale:, fallback: false, raise: true),
                       :present?
      assert_predicate I18n.t("sign.org.verification.step_up_unavailable", locale:, fallback: false, raise: true),
                       :present?
    end
  end
end
