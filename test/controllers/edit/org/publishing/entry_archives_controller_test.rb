# frozen_string_literal: true

require "test_helper"

class Edit::Org::Publishing::EntryArchivesControllerTest < ActionDispatch::IntegrationTest
  self.fixture_table_names = []

  setup do
    @host = ENV.fetch("PUBLIC_EDIT_STAFF_URL")
    host! @host
  end

  test "entry archival remains unavailable while Governance authorization is unavailable" do
    entry = publishing_draft(audience: "app", surface: "docs", slug: "step-up-required", title: "Original")

    as_rp_cell("edit-org-ww") do
      install_rp_cell_operator_jwks_client!
      sign_in_edit_rp
      origin = Rails.configuration.x.boot_config.fetch(:hosts).edit_staff.to_s
      url = OutboundHttp::LocalBackChannel.url("#{origin}/api/v0/publishing/docs/app/entries/#{entry.public_id}/archive")
      stubs =
        Faraday::Adapter::Test::Stubs.new do |stub|
          stub.post(url) { [503, { "Content-Type" => "application/problem+json" }, { status: 503 }.to_json] }
        end
      stub_outbound_http(stubs) do
        post edit_org_publishing_docs_app_entry_archive_path(entry.public_id, ri: "jp"),
             params: { archive: { reason: "Test archival" } }
      end
      stubs.verify_stubbed_calls

      assert_response :service_unavailable
      assert_not entry.reload.archived?
      assert_nil entry.archive_reason
      assert_nil entry.archived_by_operator_public_id
    end
  end
end
