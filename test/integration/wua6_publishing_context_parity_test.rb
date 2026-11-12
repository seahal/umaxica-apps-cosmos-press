# frozen_string_literal: true

require "test_helper"

class Wua6PublishingContextParityTest < ActionDispatch::IntegrationTest
  self.fixture_table_names = []

  test "Publishing API refuses unavailable governance under normal and standby credentials" do
    host! ENV.fetch("PUBLIC_EDIT_STAFF_URL")
    client = OidcClientRegistry.find!("edit-org-ww")
    path = "/api/v0/publishing/docs/org/entries"

    %w(normal standby).each do |context|
      tokens = rp_cell_test_token_response(
        client.client_id, subject: "operator:external-reference", sid: "external-session",
                          authentication_context: context,
      )

      assert_no_difference -> { Publishing::Docs::Org::Entry.count } do
        post path,
             params: { entry: { title: "Must not publish", locale: "ja", body: { text: "Blocked" }.to_json } },
             headers: { "Authorization" => "Bearer #{tokens.fetch(:access_token)}", "Accept" => "application/json" }
      end

      assert_response :service_unavailable, "#{context}: #{response.status}"
    end
  end
end
