# typed: false
# frozen_string_literal: true

require "test_helper"

# `POST /mcp` was withdrawn on 2026-09-19 (adr/mcp-endpoint-withdrawal.md): an unauthenticated
# JSON-RPC entry point kept unrouted until a follow-up ADR records its authentication, transport
# review and tool-ownership rules. This pins that the entry point stays off on the retained hosts.
class McpEndpointWithdrawalTest < ActionDispatch::IntegrationTest
  BOOT_HOSTS = Rails.configuration.x.boot_config.fetch(:hosts)
  RETAINED_HOSTS = %i(
    edit_staff
    info_service info_corporate info_staff
    news_service news_corporate news_staff
    help_service help_corporate help_staff
    docs_service docs_corporate docs_staff
  ).map { |surface| BOOT_HOSTS.public_send(surface).host }.freeze

  test "POST /mcp remains unrouted on retained hosts" do
    RETAINED_HOSTS.each do |host|
      assert_raises(ActionController::RoutingError, host) do
        Rails.application.routes.recognize_path("http://#{host}/mcp", method: :post)
      end
    end
  end

  test "a JSON-RPC request to a withdrawn endpoint is answered not found" do
    RETAINED_HOSTS.each do |host|
      host! host
      post "/mcp",
           params: { jsonrpc: "2.0", id: 1, method: "tools/list" }.to_json,
           headers: { "Host" => host, "CONTENT_TYPE" => "application/json", "HTTP_ACCEPT" => "application/json" }

      assert_response :not_found, host
    end
  end
end
