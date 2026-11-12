# typed: false
# frozen_string_literal: true

require "test_helper"

class PublishingAuthorityClientTest < ActiveSupport::TestCase
  Response = Data.define(:status, :body)

  class RecordingConnection
    def initialize(requests)
      @requests = requests
    end

    def get(uri, params, headers)
      @requests << { method: :get, uri: uri.to_s, params:, headers: }
      Response.new(status: 200, body: '{"saved":true}')
    end

    def run_request(method, uri, body, headers)
      @requests << { method:, uri: uri.to_s, body:, headers: }
      Response.new(status: 201, body: '{"saved":true}')
    end
  end

  test "read and write operations return typed authority results with request-bound assertions" do
    requests = []
    assertion_urls = []
    connection = RecordingConnection.new(requests)
    client = PublishingAuthorityClient.new(surface: "info", audience: "app", access_token: "access-token")

    OutboundHttp::Connection.stub(:build, ->(**_options) { connection }) do
      OidcClientAssertionJwt.stub(
        :issue, lambda { |client_id:, token_url:|
          assert_equal PublishingAuthorityClient::CLIENT_ID, client_id
          assertion_urls << token_url
          "client-assertion"
        },
      ) do
        results = [
          client.entries(page: 2),
          client.entry("entry-1"),
          client.create_entry(title: "New entry"),
          client.end_publication("entry-1", "publication-1", reason: "superseded"),
          client.unarchive("entry-1"),
        ]

        assert_equal %i(ok ok ok ok ok), results.map(&:status)
        assert results.all?(&:ok?)
        assert results.all? { |result| result.data == { "saved" => true } }
      end
    end

    assert_equal %i(get get post delete delete), requests.map { |request| request.fetch(:method) }
    assert_equal(
      %w(/entries /entries/entry-1 /entries /entries/entry-1/publications/publication-1 /entries/entry-1/archive),
      requests.map { |request|
        URI.parse(request.fetch(:uri)).path.split("/api/v0/publishing/info/app").last
      },
    )
    assert_equal({ page: 2 }, requests.first.fetch(:params))
    assert_includes requests[2].fetch(:body), "entry%5Btitle%5D=New+entry"
    assert_includes requests[3].fetch(:body), "reason=superseded"
    assert_nil requests.last.fetch(:body)
    assert_equal assertion_urls, requests.map { |request| request.fetch(:uri) }
    assert requests.all? { |request| request.fetch(:headers).fetch("X-Client-Assertion") == "client-assertion" }
  end
end
