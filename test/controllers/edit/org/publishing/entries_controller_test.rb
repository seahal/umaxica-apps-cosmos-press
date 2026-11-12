# frozen_string_literal: true

require "test_helper"

class Edit::Org::Publishing::EntriesControllerTest < ActionDispatch::IntegrationTest
  self.fixture_table_names = []

  setup do
    @host = ENV.fetch("PUBLIC_EDIT_STAFF_URL")
    host! @host
  end

  test "entry changes remain unavailable while Governance authorization is unavailable" do
    entry = publishing_draft(audience: "app", surface: "docs", slug: "step-up-required", title: "Original")
    revision_count = entry.revisions.count

    as_rp_cell("edit-org-ww") do
      install_rp_cell_operator_jwks_client!
      sign_in_edit_rp
      origin = Rails.configuration.x.boot_config.fetch(:hosts).edit_staff.to_s
      url = OutboundHttp::LocalBackChannel.url("#{origin}/api/v0/publishing/docs/app/entries/#{entry.public_id}")
      stubs =
        Faraday::Adapter::Test::Stubs.new do |stub|
          stub.patch(url) { [503, { "Content-Type" => "application/problem+json" }, { status: 503 }.to_json] }
        end
      stub_outbound_http(stubs) do
        patch edit_org_publishing_docs_app_entry_path(entry.public_id, ri: "jp"),
              params: {
                entry: {
                  title: "Must not be applied",
                  summary: "Blocked until local step-up exists",
                  body: { "text" => "Must not be applied" }.to_json,
                  lock_version: entry.lock_version,
                },
              }
      end
      stubs.verify_stubbed_calls

      assert_response :service_unavailable
      assert_equal "Original", entry.reload.current_revision.title
      assert_equal revision_count, entry.revisions.count
    end
  end
end
