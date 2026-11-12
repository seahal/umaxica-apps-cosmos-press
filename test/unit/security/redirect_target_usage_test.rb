# frozen_string_literal: true

require "test_helper"
# require "helpers/global_test_support"

class RedirectTargetUsageTest < ActiveSupport::TestCase
  DIRECT_PARAM_REDIRECT = /redirect_to\s*\(?\s*params\[/.freeze
  DIRECT_ALLOW_OTHER_HOST = /allow_other_host:\s*true/.freeze
  LEGACY_XT_REDIRECT = /\bredirect_to_xt(?:_url)?\b/.freeze

  # Every entry builds its target from a route helper with a configured host, or from a destination
  # persisted and validated when its transaction was issued. None reads the target from a parameter.
  ALLOW_OTHER_HOST_ALLOWLIST = %w(
    app/controllers/concerns/common_redirect.rb
    app/controllers/concerns/oidc_rp_logout_launcher.rb
    app/controllers/concerns/oidc_sso_initiator.rb
  ).freeze

  test "controllers do not redirect directly to params" do
    offenders =
      ruby_files.grep(%r{\Aapp/controllers/}).select do |path|
        File.read(path).match?(DIRECT_PARAM_REDIRECT)
      end

    assert_empty offenders
  end

  test "allow_other_host true is limited to reviewed Jump and protocol handoff boundaries" do
    users = ruby_files.select { |path| File.read(path).match?(DIRECT_ALLOW_OTHER_HOST) }

    assert_equal ALLOW_OTHER_HOST_ALLOWLIST.sort, users.sort
  end

  test "legacy xt redirect facade is not used" do
    offenders =
      ruby_files.select do |path|
        File.read(path).match?(LEGACY_XT_REDIRECT)
      end

    assert_empty offenders
  end

  private

  def ruby_files
    Dir.glob("{app,config,lib}/**/*.rb")
  end
end
