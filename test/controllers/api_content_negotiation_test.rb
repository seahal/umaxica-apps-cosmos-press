# typed: false
# frozen_string_literal: true

require "test_helper"

# Covers the media type contract on a retained public content API.
class ApiContentNegotiationTest < ActionDispatch::IntegrationTest
  DOCS_HOST = ENV.fetch("PRIVATE_DOCS_SERVICE_URL")

  setup do
    host! DOCS_HOST
    https!
  end

  test "a caller that accepts only html is refused on the content api" do
    get "/api/v0/entries", headers: { "Accept" => "text/html" }

    assert_response :not_acceptable
    assert_equal "application/problem+json", response.media_type
    assert_equal "urn:umaxica:problem:not-acceptable", response.parsed_body.fetch("type")
  end

  # RFC 9110 15.5.7 allows a 406 to carry a representation the client did not ask for, and an
  # explanation the caller can read beats an empty body.
  test "the refusal itself is still a problem document" do
    get "/api/v0/entries", headers: { "Accept" => "text/csv" }

    assert_response :not_acceptable

    body = response.parsed_body

    assert_equal 406, body.fetch("status")
    assert_predicate body.fetch("request_id"), :present?
  end

  test "an absent Accept header accepts anything" do
    get "/api/v0/entries"

    assert_response :success
    assert_equal "application/json", response.media_type
  end

  test "wildcard and subtype ranges are accepted" do
    ["*/*", "application/*", "text/html,application/xhtml+xml,*/*;q=0.8"].each do |accept|
      get "/api/v0/entries", headers: { "Accept" => accept }

      assert_response :success, "Accept: #{accept} was refused"
    end
  end

  test "a caller that accepts only the problem media type is served" do
    get "/api/v0/entries", headers: { "Accept" => "application/problem+json" }

    assert_response :success
  end
end
