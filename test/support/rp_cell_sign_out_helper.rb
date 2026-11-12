# frozen_string_literal: true

require_relative "rp_cell_session_helper"

# Uses external credentials while verifying local revocation before an external RFC 7009 call.
module RpCellSignOutHelper
  def authenticate_rp_cell_for_sign_out!(client_id: "edit-org-ww", subject: "operator:external-reference")
    @rp_cell_client = OidcClientRegistry.find!(client_id)
    @rp_cell_resource_type = OidcIssuer.resource_type_for_client(@rp_cell_client)
    @rp_cell_token_response, @rp_cell_payload, @rp_cell_session = sign_in_edit_rp(subject:)
  end

  def post_rp_cell_sign_out(path, params: {}, headers: {})
    @rp_cell_revocation_calls = []
    local_session = @rp_cell_session
    result = Object.new
    result.define_singleton_method(:success?) { false }
    result.define_singleton_method(:outcome) { :network_unavailable }

    OidcOpRevocationClient.stub(
      :revoke,
      ->(**arguments) {
        @rp_cell_revocation_calls << arguments.merge(local_session_revoked: local_session.reload.revoked_at.present?)
        result
      },
    ) do
      post(path, params:, headers:)
    end
  end

  def assert_rp_cell_sign_out_handoff!(client_id:, region:)
    client = OidcClientRegistry.find!(client_id)
    resource_type = OidcIssuer.resource_type_for_client(client)
    location = URI.parse(response.location)
    query = Rack::Utils.parse_nested_query(location.query.to_s)
    redirect_uri =
      client.post_logout_redirect_uris.find do |candidate|
        Rack::Utils.parse_nested_query(URI.parse(candidate).query.to_s)["ri"] == region.to_s
      end

    assert_response :see_other
    assert_rp_cell_visa_logout_redirect!(
      client:, client_id:, redirect_uri:, location:, query:,
    )
    assert_rp_cell_local_logout_revocation!(client_id:, resource_type:)
    assert_predicate @rp_cell_session.reload.revoked_at, :present?
  end

  private

  def assert_rp_cell_visa_logout_redirect!(client:, client_id:, redirect_uri:, location:, query:)
    assert_equal OidcIssuer.host_for_client(client), location.host
    assert_equal "/oidc/logout", location.path
    assert_equal client_id, query.fetch("client_id")
    assert_not query.key?("id_token_hint")
    assert_equal redirect_uri, query.fetch("post_logout_redirect_uri")
    assert_predicate query.fetch("state"), :present?
  end

  def assert_rp_cell_local_logout_revocation!(client_id:, resource_type:)
    assert_equal @rp_cell_token_response.fetch(:refresh_token), @rp_cell_revocation_calls.fetch(0).fetch(:token)
    assert_equal resource_type, @rp_cell_revocation_calls.fetch(0).fetch(:resource_type)
    assert_equal client_id, @rp_cell_revocation_calls.fetch(0).fetch(:client_id)
    assert @rp_cell_revocation_calls.fetch(0).fetch(:local_session_revoked)
  end
end
