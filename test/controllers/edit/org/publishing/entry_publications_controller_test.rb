# frozen_string_literal: true

require "test_helper"

class Edit::Org::Publishing::EntryPublicationsControllerTest < ActionDispatch::IntegrationTest
  self.fixture_table_names = []

  setup do
    @host = ENV.fetch("PUBLIC_EDIT_STAFF_URL")
    host! @host
  end

  test "entry publication remains unavailable while Governance authorization is unavailable" do
    entry = publishing_draft(audience: "app", surface: "docs", slug: "step-up-required", title: "Original")

    as_rp_cell("edit-org-ww") do
      install_rp_cell_operator_jwks_client!
      sign_in_edit_rp
      origin = Rails.configuration.x.boot_config.fetch(:hosts).edit_staff.to_s
      url = OutboundHttp::LocalBackChannel.url("#{origin}/api/v0/publishing/docs/app/entries/#{entry.public_id}/publications")
      stubs =
        Faraday::Adapter::Test::Stubs.new do |stub|
          stub.post(url) { [503, { "Content-Type" => "application/problem+json" }, { status: 503 }.to_json] }
        end
      stub_outbound_http(stubs) do
        post edit_org_publishing_docs_app_entry_publications_path(entry.public_id, ri: "jp")
      end
      stubs.verify_stubbed_calls

      assert_response :service_unavailable
      assert_equal 0, Publishing::Docs::App::Publication.where(entry_id: entry.id).count
      assert_nil Publishing::Docs::App::Publication.find_by(entry_id: entry.id)
    end
  end
end
