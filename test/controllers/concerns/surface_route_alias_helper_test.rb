# frozen_string_literal: true

require "test_helper"

class SurfaceRouteAliasHelperTest < ActiveSupport::TestCase
  class Probe
    include SurfaceRouteAliasHelper

    def auth_app_sign_in_path(region:)
      "/auth/sign-in?region=#{region}"
    end
  end

  test "advertises and dispatches a supported route alias" do
    helper = Probe.new

    assert_respond_to helper, :sign_app_sign_in_path
    assert_equal "/auth/sign-in?region=jp", helper.sign_app_sign_in_path(region: "jp")
  end

  test "does not claim unknown helpers" do
    helper = Probe.new

    assert_not helper.respond_to?(:sign_app_unknown_path)
    assert_raises(NoMethodError) { helper.sign_app_unknown_path }
  end
end
