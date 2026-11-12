# typed: false
# frozen_string_literal: true

require "test_helper"

class OidcRpBrowserCredentialContractTest < ActiveSupport::TestCase
  test "RP cookie names follow the local contract" do
    assert_equal "__Host-rp-access", OidcRpCookieName.access(production: true)
    assert_equal "__Host-rp-refresh", OidcRpCookieName.refresh(production: true)
    assert_equal "rp-access", OidcRpCookieName.access(production: false)
    assert_equal "rp-refresh", OidcRpCookieName.refresh(production: false)
  end

  test "RP cookie flags and expiries come from the token response" do
    now = Time.utc(2026, 10, 6, 1, 0, 0)
    response = {
      access_token: "access",
      refresh_token: "refresh",
      expires_in: 300,
      refresh_token_expires_in: 3600,
    }

    expiries = OidcRpBrowserCredentialContract.cookie_expiries_from_response(response, now: now)
    access = OidcRpBrowserCredentialContract.access_cookie_options(expires_at: expiries.fetch(:access_expires_at))
    refresh = OidcRpBrowserCredentialContract.refresh_cookie_options(expires_at: expiries.fetch(:refresh_expires_at))

    assert_equal now + 5.minutes, expiries.fetch(:access_expires_at)
    assert_equal now + 1.hour, expiries.fetch(:refresh_expires_at)
    [access, refresh].each do |options|
      assert_equal JitSessionCookieConfig.force_secure?, options.fetch(:secure)
      assert options.fetch(:httponly)
      assert_equal :lax, options.fetch(:same_site)
      assert_equal "/", options.fetch(:path)
      assert_not options.key?(:domain)
      assert_predicate options.fetch(:expires), :present?
    end
  end

  test "a reversed response expiry is rejected instead of extending refresh authority" do
    error =
      assert_raises(ArgumentError) do
        OidcRpBrowserCredentialContract.cookie_expiries_from_response(
          { expires_in: 301, refresh_token_expires_in: 300 },
        )
      end

    assert_match(/precedes access expiry/, error.message)
  end

  test "a token response without server expiry cannot create an RP cookie" do
    assert_raises(ArgumentError) do
      OidcRpBrowserCredentialContract.cookie_expiries_from_response(
        { access_token: "access", refresh_token: "refresh", expires_in: 300 },
      )
    end
  end

  test "each credential cookie requires its own absolute expiry" do
    calls = [
      [:access_cookie_options, {}, "RP access cookie expiry is required"],
      [:refresh_cookie_options, {}, "RP refresh cookie expiry is required"],
      [:session_cookie_options, { expires_at: nil }, "RP session cookie expiry is required"],
    ]
    calls.each do |method_name, options, message|
      error =
        assert_raises(ArgumentError) do
          OidcRpBrowserCredentialContract.public_send(method_name, **options)
        end

      assert_equal message, error.message
    end
  end

  test "token response requires nonblank access and refresh tokens with either key form" do
    assert_equal ["access", "refresh"], OidcRpBrowserCredentialContract.require_token_response!(
      { :access_token => "access", "refresh_token" => "refresh" },
    )
    assert_equal ["access", "refresh"], OidcRpBrowserCredentialContract.require_token_response!(
      { "access_token" => "access", :refresh_token => "refresh" },
    )

    [
      { access_token: nil, refresh_token: "refresh" },
      { access_token: "access", refresh_token: "" },
    ].each do |response|
      error =
        assert_raises(ArgumentError) do
          OidcRpBrowserCredentialContract.require_token_response!(response)
        end

      assert_equal "RP token response is incomplete", error.message
    end
  end

  test "expiry conversion honors an explicit absolute expiry before duration parsing" do
    now = Time.utc(2026, 10, 6, 1, 0, 0)
    expires_at = now + 1.hour

    assert_equal expires_at, OidcRpBrowserCredentialContract.expiry_from(
      "malformed-duration", expires_at:, now:,
    )
  end

  test "expiry conversion accepts integer and decimal-string durations at zero and positive boundaries" do
    now = Time.utc(2026, 10, 6, 1, 0, 0)

    assert_equal now, OidcRpBrowserCredentialContract.expiry_from(0, expires_at: nil, now:)
    assert_equal now + 1.second, OidcRpBrowserCredentialContract.expiry_from(1, expires_at: nil, now:)
    assert_equal now + 60.seconds, OidcRpBrowserCredentialContract.expiry_from("60", expires_at: nil, now:)
  end

  test "expiry conversion returns nil only when both expiry sources are absent" do
    assert_nil OidcRpBrowserCredentialContract.expiry_from(nil, expires_at: nil, now: Time.utc(2026, 10, 6))
  end

  test "expiry conversion rejects negative malformed and unsupported durations" do
    now = Time.utc(2026, 10, 6, 1, 0, 0)

    [-1, "malformed-duration", 1.5].each do |expires_in|
      error =
        assert_raises(ArgumentError) do
          OidcRpBrowserCredentialContract.expiry_from(expires_in, expires_at: nil, now:)
        end

      assert_equal "RP token expiry is invalid", error.message
    end
  end

  test "token response expiry accepts symbol and string keys at zero and positive boundaries" do
    now = Time.utc(2026, 10, 6, 1, 0, 0)

    assert_equal now, OidcRpBrowserCredentialContract.access_expires_at_from_response(
      { expires_in: 0 }, now:,
    )
    assert_equal now + 1.second, OidcRpBrowserCredentialContract.access_expires_at_from_response(
      { :expires_in => nil, "expires_in" => "1" }, now:,
    )
    assert_equal now + 60.seconds, OidcRpBrowserCredentialContract.refresh_expires_at_from_response(
      { "refresh_token_expires_in" => "60" }, now:,
    )
  end

  test "token response expiry rejects non-hashes missing values and invalid durations" do
    now = Time.utc(2026, 10, 6, 1, 0, 0)
    responses = [nil, [], { expires_in: nil }, { expires_in: -1 }, { expires_in: "invalid" }, { expires_in: 1.5 }]
    responses.each do |response|
      error =
        assert_raises(ArgumentError) do
          OidcRpBrowserCredentialContract.access_expires_at_from_response(response, now:)
        end

      assert_equal "RP token response expires_in is invalid", error.message
    end
  end
end
