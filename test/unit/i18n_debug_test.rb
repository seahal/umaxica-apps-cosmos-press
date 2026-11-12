# typed: false
# frozen_string_literal: true

require "test_helper"

class I18nDebugTest < ActiveSupport::TestCase
  test "retained Edit verification translations exist" do
    I18n.with_locale(:ja) do
      assert I18n.exists?("errors.otp_locked"), "ja.errors.otp_locked missing"
      assert I18n.exists?("sign.org.verification.step_up_unavailable"),
             "ja.sign.org.verification.step_up_unavailable missing"
    end

    I18n.with_locale(:en) do
      assert I18n.exists?("auth.step_up.challenge.title"), "en.auth.step_up.challenge.title missing"
      assert I18n.exists?("sign.org.verification.step_up_unavailable"),
             "en.sign.org.verification.step_up_unavailable missing"
    end
  end
end
