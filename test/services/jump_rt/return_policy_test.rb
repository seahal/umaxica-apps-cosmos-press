# typed: false
# frozen_string_literal: true

require "test_helper"
# require "helpers/global_test_support"

class JumpRtReturnPolicyTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "normalize_origin returns nil for invalid URI" do
    assert_nil JumpRtReturnPolicy.normalize_origin("not a url")
  end

  test "normalize_origin returns nil for non-http scheme" do
    assert_nil JumpRtReturnPolicy.normalize_origin("ftp://example.com")
  end

  test "normalize_origin returns nil for URI with userinfo" do
    assert_nil JumpRtReturnPolicy.normalize_origin("https://user:pass@www.umaxica.app")
  end

  test "origins with a path query or fragment are rejected" do
    ["https://auth.umaxica.app/", "https://auth.umaxica.app/path",
     "https://auth.umaxica.app?x=1", "https://auth.umaxica.app#fragment",].each do |origin|
      assert_nil JumpRtReturnPolicy.normalize_origin(origin), origin
      assert_not JumpRtReturnPolicy.allowed_source?(destination_origin: "https://www.umaxica.app", source: origin)
    end
  end

  test "normalize_origin normalizes https origin" do
    result = JumpRtReturnPolicy.normalize_origin("https://www.umaxica.app")

    assert_equal "https://www.umaxica.app", result
  end

  test "normalize_origin normalizes http origin" do
    result = JumpRtReturnPolicy.normalize_origin("http://example.com")

    assert_equal "http://example.com", result
  end

  test "normalize_origin downcases host" do
    result = JumpRtReturnPolicy.normalize_origin("https://WWW.UMAXICA.APP")

    assert_equal "https://www.umaxica.app", result
  end

  test "normalize_origin includes non-default port" do
    result = JumpRtReturnPolicy.normalize_origin("https://www.umaxica.app:8443")

    assert_equal "https://www.umaxica.app:8443", result
  end

  test "normalize_origin omits default https port" do
    result = JumpRtReturnPolicy.normalize_origin("https://www.umaxica.app:443")

    assert_equal "https://www.umaxica.app", result
  end

  test "normalize_origin omits default http port" do
    result = JumpRtReturnPolicy.normalize_origin("http://example.com:80")

    assert_equal "http://example.com", result
  end

  test "normalize_origin returns nil for blank host" do
    assert_nil JumpRtReturnPolicy.normalize_origin("https://")
  end

  test "allowed_source returns false for unauthorized source" do
    assert_not JumpRtReturnPolicy.allowed_source?(
      destination_origin: "https://www.umaxica.app",
      source: "https://evil.example.com",
    )
  end

  test "allowed_source returns false when destination origin is unknown" do
    assert_not JumpRtReturnPolicy.allowed_source?(
      destination_origin: "https://unknown.example.com",
      source: "https://auth.umaxica.app",
    )
  end

  test "default_port_for returns 443 for https" do
    assert_equal 443, JumpRtReturnPolicy.default_port_for("https")
  end

  test "default_port_for returns 80 for http" do
    assert_equal 80, JumpRtReturnPolicy.default_port_for("http")
  end

  test "Press does not accept another repository's directed Jump edges as its own" do
    origins = %w(
      https://auth.example.invalid https://base.example.invalid https://visa.example.invalid
      https://core.example.invalid https://warp.example.invalid https://palm.example.invalid
      https://edit.example.invalid
    )

    origins.product(origins).each do |source, destination|
      assert_not JumpRtReturnPolicy.allowed_source?(destination_origin: destination, source: source)
    end
  end

  test "unregistered stale private and sentinel origins are denied in either direction" do
    [nil, "", "https://zzzz.umaxica.app", "https://www.umaxica.zzz",
     "https://www-zz.umaxica.app", "https://www.jp.umaxica.app", "https://jpx.umaxica.app",
     "https://palm.jp.umaxica.app", "https://edit.umaxica.org", "http://base.app.localhost",
     "https://base.app.localhost", "https://127.0.0.1",].each do |origin|
      assert_not JumpRtReturnPolicy.allowed_source?(destination_origin: "https://www.umaxica.app", source: origin)
      assert_not JumpRtReturnPolicy.allowed_source?(destination_origin: origin, source: "https://www.umaxica.app")
    end
  end

  test "retired logical ceremony issuer is not a jump return source" do
    %w(app com org).each do |tld|
      assert_not JumpRtReturnPolicy.allowed_source?(
        destination_origin: "https://www.umaxica.#{tld}",
        source: "https://log.umaxica.#{tld}",
      ), tld
      assert_not JumpRtReturnPolicy.allowed_source?(
        destination_origin: "https://www.jp.umaxica.#{tld}",
        source: "https://log.umaxica.#{tld}",
      ), tld
    end
  end
end
