# frozen_string_literal: true

require "test_helper"

class CredentialDeletionFinalizerTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "register keeps only cookie identity attributes for the response boundary" do
    environment = {}

    CredentialDeletionFinalizer.register(
      environment,
      "_umaxica_session",
      { path: "/", secure: true, httponly: true, value: "secret", domain: "example.invalid" },
    )

    assert_equal(
      { "_umaxica_session" => { path: "/", secure: true, httponly: true } },
      environment.fetch(CredentialDeletionFinalizer::ENV_KEY),
    )
    assert_raises(ArgumentError) { CredentialDeletionFinalizer.register({}, "", {}) }
  end

  test "call does not delete a credential cookie when the final response already writes it" do
    headers = { Rack::SET_COOKIE => "rp-access=rotated; Path=/\nother=value; Path=/" }
    body = ["not found"]
    environment = {
      CredentialDeletionFinalizer::ENV_KEY => { "rp-access" => { path: "/", secure: true, httponly: true } },
    }

    status, response_headers, response_body = CredentialDeletionFinalizer.new(
      ->(_env) { [404, headers, body] },
    ).call(environment)

    assert_equal 404, status
    assert_same headers, response_headers
    assert_same body, response_body
    assert_equal "rp-access=rotated; Path=/\nother=value; Path=/", response_headers.fetch(Rack::SET_COOKIE)
  end

  test "call appends a registered deletion while preserving other Set-Cookie headers" do
    headers = { Rack::SET_COOKIE => ["other=value; Path=/"] }
    body = ["not found"]
    environment = {
      CredentialDeletionFinalizer::ENV_KEY => { "rp-access" => { path: "/", secure: true, httponly: true } },
    }

    status, response_headers, response_body = CredentialDeletionFinalizer.new(
      ->(_env) { [404, headers, body] },
    ).call(environment)

    set_cookie_lines = Array(response_headers.fetch(Rack::SET_COOKIE))

    assert_equal 404, status
    assert_same body, response_body
    assert_equal 2, set_cookie_lines.length
    assert_includes set_cookie_lines, "other=value; Path=/"
    assert_match(/\Arp-access=; .*max-age=0/i, set_cookie_lines.last)
  end
end
