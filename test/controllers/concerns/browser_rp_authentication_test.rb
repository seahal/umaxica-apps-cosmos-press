# typed: false
# frozen_string_literal: true

require "test_helper"

# Wired like a production Browser RP controller: the shared authentication concern, then the two
# refresh orchestrators in the same callback positions.
module Edit
  module Org
    class BrowserRpAuthenticationProbeController < ::ApplicationController
      include ::BrowserRpAuthentication
      include ::BrowserRpSafeRequestRefresh
      include ::BrowserRpUnsafeRequestRefresh
      include ::OidcSsoInitiator

      protect_from_forgery with: :exception
      before_action :authenticate_browser_rp_safe_request!
      prepend_before_action :authenticate_browser_rp_unsafe_request!
      before_action :enforce_access_policy!, only: %i(open_probe guest_probe deny_all_probe)
      access_policy :public_strict, only: :policy_probe, probe_policy: "configured"
      declare_authentication_mode! :open, only: :open_probe
      declare_authentication_mode! :guest, only: :guest_probe
      declare_authentication_mode! :deny_all, only: :deny_all_probe

      def show
        if (params[:required] == "1") && !authenticate_browser_rp!
          return
        end

        render plain: current_resource&.public_id.to_s
      end

      def csrf
        render plain: form_authenticity_token
      end

      def update
        return unless authenticate_browser_rp!

        render plain: "mutated"
      end

      def helpers
        render json: {
          current_resource: current_resource&.public_id,
          current_session: current_session&.public_id,
          current_session_public_id: current_session_public_id,
          browser_rp_session_public_id: browser_rp_session_public_id,
          browser_rp_controller: browser_rp_controller?,
          logged_in_operator: logged_in_operator?,
          operator: am_i_operator?,
          staff: am_i_staff?,
          resource_type: resource_type,
        }
      end

      def policy_probe
        mode_policy = policy_for_authentication_mode(self.class.authentication_mode_for(action_name))
        options = access_policy_options_for(action_name)
        context = access_policy_context(mode_policy, options)
        allowed = access_policy_allows?(:probe_rule, context)
        render json: {
          mode_policy:,
          options:,
          current_resource_deactivated: context.current_resource_deactivated,
          allowed:,
        }
      end

      def open_probe
        render plain: "open"
      end

      def guest_probe
        render plain: "guest"
      end

      def deny_all_probe
        render plain: "unreachable"
      end

      def authenticate_probe
        authenticate!
        render plain: "authenticated" unless performed?
      end

      protected

      def browser_rp_client_id = "edit-org-ww"

      def browser_rp_resource_type = "operator"

      def browser_rp_trusted_origins = [request.base_url]

      def oidc_client_id = "edit-org-ww"

      def oidc_sign_host = Rails.configuration.x.boot_config.fetch(:hosts).auth_staff.host

      def oidc_visa_authority_host = Rails.configuration.x.boot_config.fetch(:hosts).visa_staff.host
    end

    class BrowserRpAuthenticationDefaultProbeController < ::ApplicationController
      include ::BrowserRpAuthentication

      AUTHENTICATION_MODE = :open

      def trusted_origins
        browser_rp_trusted_origins
      end

      def client_id_probe
        browser_rp_client_id
      end

      def resource_type_probe
        resource_type
      end
    end
  end

  class BrowserRpAuthenticationSkipProbeController < ApplicationController
    include ::BrowserRpAuthentication

    before_action :probe_filter

    def self.skip_probe_filter!
      skip_before_action :probe_filter
    end
  end
end

class BrowserRpAuthenticationTest < ActionController::TestCase
  include RpCellSessionHelper

  tests Edit::Org::BrowserRpAuthenticationProbeController

  setup do
    @routes = ActionDispatch::Routing::RouteSet.new
    @routes.draw do
      get "/csrf" => "edit/org/browser_rp_authentication_probe#csrf"
      get "/probe" => "edit/org/browser_rp_authentication_probe#show"
      get "/helpers" => "edit/org/browser_rp_authentication_probe#helpers"
      get "/policy" => "edit/org/browser_rp_authentication_probe#policy_probe"
      get "/open" => "edit/org/browser_rp_authentication_probe#open_probe"
      get "/guest" => "edit/org/browser_rp_authentication_probe#guest_probe"
      get "/deny-all" => "edit/org/browser_rp_authentication_probe#deny_all_probe"
      get "/authenticate" => "edit/org/browser_rp_authentication_probe#authenticate_probe"
      patch "/probe" => "edit/org/browser_rp_authentication_probe#update"
    end
    @request.host = Rails.configuration.x.boot_config.fetch(:hosts).edit_staff.host
    @previous_jwks_clients = OidcOpJwksClient::CLIENTS.dup
    install_rp_cell_operator_jwks_client!
    @tokens, @payload, @local_session = sign_in_edit_rp
    @local_session =
      RpEditOrgSession.includes(op_session_binding: { identity_binding: :principal }).find(@local_session.id)
  end

  teardown do
    OidcOpJwksClient::CLIENTS.clear
    @previous_jwks_clients.each { |key, value| OidcOpJwksClient::CLIENTS[key] = value }
  end

  test "valid external access and local session authenticate without a refresh call" do
    OidcOpTokenClient.stub(:refresh, ->(**) { flunk("valid access must not refresh") }) do
      get :show, params: { required: "1" }
    end

    assert_response :success
    assert_equal @local_session.op_session_binding.identity_binding.principal.public_id, response.body
  end

  test "shared runtime uses the same local session rather than OP storage" do
    previous = ENV["UMAXICA_RUNTIME_ROLE"]
    ENV["UMAXICA_RUNTIME_ROLE"] = "shared"
    get(:show, params: { required: "1" })

    assert_response :success
    assert_equal @local_session.op_session_binding.identity_binding.principal.public_id, response.body
  ensure
    previous.nil? ? ENV.delete("UMAXICA_RUNTIME_ROLE") : ENV["UMAXICA_RUNTIME_ROLE"] = previous
  end

  test "no RP credentials cannot authenticate or consult the external refresh authority" do
    cookies.delete(OidcRpBrowserCredentialContract::ACCESS_COOKIE)
    cookies.delete(OidcRpBrowserCredentialContract::REFRESH_COOKIE)
    cookies.delete(OidcRpBrowserCredentialContract::SESSION_COOKIE)
    OidcOpTokenClient.stub(:refresh, ->(**) { flunk("missing credentials must not refresh") }) do
      get :show, params: { required: "1" }
    end

    assert_response :redirect
  end

  test "an external access token with the wrong audience cannot authenticate this RP" do
    replace_access_claim("aud", ["another-client"])
    cookies.delete(OidcRpBrowserCredentialContract::REFRESH_COOKIE)
    get :show, params: { required: "1" }

    assert_response :redirect
    assert_empty cookies[OidcRpBrowserCredentialContract::ACCESS_COOKIE].to_s
  end

  test "missing local credential cannot authenticate a valid external access token" do
    cookies.delete(OidcRpBrowserCredentialContract::SESSION_COOKIE)
    cookies.delete(OidcRpBrowserCredentialContract::REFRESH_COOKIE)
    get :show, params: { required: "1" }

    assert_response :redirect
    assert_not_equal @local_session.op_session_binding.identity_binding.principal.public_id, response.body
  end

  test "revoked local binding refuses the same signed access token" do
    @local_session.op_session_binding.update!(revoked_at: Time.current)
    cookies.delete(OidcRpBrowserCredentialContract::REFRESH_COOKIE)
    get :show, params: { required: "1" }

    assert_response :redirect
    assert_empty cookies[OidcRpBrowserCredentialContract::ACCESS_COOKIE].to_s
  end

  test "disabled local principal refuses the same signed access token" do
    @local_session.op_session_binding.identity_binding.principal.update!(disabled_at: Time.current)
    cookies.delete(OidcRpBrowserCredentialContract::REFRESH_COOKIE)
    get :show, params: { required: "1" }

    assert_response :redirect
    assert_empty cookies[OidcRpBrowserCredentialContract::ACCESS_COOKIE].to_s
  end

  test "a signed access token for another subject cannot use this local session" do
    replace_access_claim("sub", "operator:another-external-subject")
    cookies.delete(OidcRpBrowserCredentialContract::REFRESH_COOKIE)
    get :show, params: { required: "1" }

    assert_response :redirect
    assert_empty cookies[OidcRpBrowserCredentialContract::ACCESS_COOKIE].to_s
  end

  test "a signed access token for another sid cannot use this local session" do
    replace_access_claim("sid", SecureRandom.urlsafe_base64(24))
    cookies.delete(OidcRpBrowserCredentialContract::REFRESH_COOKIE)
    get :show, params: { required: "1" }

    assert_response :redirect
    assert_empty cookies[OidcRpBrowserCredentialContract::ACCESS_COOKIE].to_s
  end

  test "another issuer is refused before fetching an external key" do
    replace_access_claim("iss", "https://untrusted.example")
    cookies.delete(OidcRpBrowserCredentialContract::REFRESH_COOKIE)
    jwks_client = OidcOpJwksClient.for_resource_type("operator")
    jwks_client.stub(:lookup, ->(*) { flunk("wrong issuer must not fetch a key") }) do
      get :show, params: { required: "1" }
    end

    assert_response :redirect
    assert_empty cookies[OidcRpBrowserCredentialContract::ACCESS_COOKIE].to_s
  end

  test "database dependency failure preserves all browser credentials and answers 503" do
    RpRequestAuthenticator.stub(:call, ->(**) { raise ActiveRecord::ConnectionTimeoutError }) do
      get :show, params: { required: "1" }
    end

    assert_response :service_unavailable
    assert_equal @tokens.fetch(:access_token), cookies[OidcRpBrowserCredentialContract::ACCESS_COOKIE]
    assert_equal @tokens.fetch(:refresh_token), cookies[OidcRpBrowserCredentialContract::REFRESH_COOKIE]
    assert_equal @local_session.public_id, cookies[OidcRpBrowserCredentialContract::SESSION_COOKIE]
  end

  test "unavailable JWKS preserves all browser credentials and answers 503" do
    OidcOpJwksClient.stub(:for_resource_type, ->(*) { raise OidcOpJwksClient::FetchError }) do
      get :show, params: { required: "1" }
    end

    assert_response :service_unavailable
    assert_equal @tokens.fetch(:access_token), cookies[OidcRpBrowserCredentialContract::ACCESS_COOKIE]
    assert_equal @tokens.fetch(:refresh_token), cookies[OidcRpBrowserCredentialContract::REFRESH_COOKIE]
  end

  test "unsafe cross-origin request cannot refresh or mutate" do
    @request.headers["Origin"] = "https://attacker.example"
    OidcOpTokenClient.stub(:refresh, ->(**) { flunk("unsafe request must not dispatch refresh") }) do
      patch :update
    end

    assert_response :unprocessable_content
    assert_not_equal "mutated", response.body
    assert_equal @tokens.fetch(:refresh_token), cookies[OidcRpBrowserCredentialContract::REFRESH_COOKIE]
  end

  test "unsafe null-origin request cannot refresh or mutate" do
    @request.headers["Origin"] = "null"
    OidcOpTokenClient.stub(:refresh, ->(**) { flunk("null origin must not dispatch refresh") }) do
      patch :update
    end

    assert_response :unprocessable_content
    assert_not_equal "mutated", response.body
  end

  test "expired access refreshes once through the external endpoint and installs the local generation" do
    replace_access_claim("exp", 2.minutes.ago.to_i)
    refreshed = rp_cell_test_token_response("edit-org-ww", subject: @payload.fetch("sub"), sid: @payload.fetch("sid"))
    calls = []
    result = OidcOpTokenClient::Result.new(outcome: :success, token_response: refreshed, error: nil)
    OidcOpTokenClient.stub(
      :refresh, ->(**args) {
                  calls << args
                  result
                },
    ) do
      get :show, params: { required: "1" }
    end

    assert_response :success
    assert_equal 1, calls.length
    assert_equal @tokens.fetch(:refresh_token), calls.first.fetch(:refresh_token)
    assert_equal refreshed.fetch(:access_token), cookies[OidcRpBrowserCredentialContract::ACCESS_COOKIE]
    assert_equal refreshed.fetch(:refresh_token), cookies[OidcRpBrowserCredentialContract::REFRESH_COOKIE]
    assert_equal 1, @local_session.reload.installed_generation
  end

  test "definitively refused refresh clears every local browser credential" do
    replace_access_claim("exp", 2.minutes.ago.to_i)
    result = OidcOpTokenClient::Result.new(outcome: :refused, token_response: nil, error: "invalid_grant")
    OidcOpTokenClient.stub(:refresh, ->(**) { result }) do
      get :show, params: { required: "1" }
    end

    assert_response :redirect
    assert_empty cookies[OidcRpBrowserCredentialContract::ACCESS_COOKIE].to_s
    assert_empty cookies[OidcRpBrowserCredentialContract::REFRESH_COOKIE].to_s
    assert_empty cookies[OidcRpBrowserCredentialContract::SESSION_COOKIE].to_s
  end

  test "indeterminate refresh clears credentials instead of replaying a potentially rotated token" do
    replace_access_claim("exp", 2.minutes.ago.to_i)
    calls = 0
    result = OidcOpTokenClient::Result.new(outcome: :indeterminate, token_response: nil, error: "timeout")
    OidcOpTokenClient.stub(
      :refresh, ->(**) {
                  calls += 1
                  result
                },
    ) do
      get :show, params: { required: "1" }
    end

    assert_equal 1, calls
    assert_response :redirect
    assert_empty cookies[OidcRpBrowserCredentialContract::REFRESH_COOKIE].to_s
    assert_empty cookies[OidcRpBrowserCredentialContract::SESSION_COOKIE].to_s
  end

  test "pre-dispatch refresh dependency failure preserves cookies and local installed generation" do
    replace_access_claim("exp", 2.minutes.ago.to_i)
    expired_access = cookies[OidcRpBrowserCredentialContract::ACCESS_COOKIE]
    result = OidcOpTokenClient::Result.new(outcome: :dependency, token_response: nil, error: "unavailable")
    OidcOpTokenClient.stub(:refresh, ->(**) { result }) do
      get :show, params: { required: "1" }
    end

    assert_response :service_unavailable
    assert_equal expired_access, cookies[OidcRpBrowserCredentialContract::ACCESS_COOKIE]
    assert_equal @tokens.fetch(:refresh_token), cookies[OidcRpBrowserCredentialContract::REFRESH_COOKIE]
    assert_equal @local_session.public_id, cookies[OidcRpBrowserCredentialContract::SESSION_COOKIE]
    assert_equal 0, @local_session.reload.installed_generation
  end

  test "unsafe missing CSRF cannot dispatch refresh or reach mutation" do
    previous = @controller.allow_forgery_protection
    @controller.allow_forgery_protection = true
    @request.headers["Origin"] = request.base_url
    replace_access_claim("exp", 2.minutes.ago.to_i)
    OidcOpTokenClient.stub(:refresh, ->(**) { flunk("CSRF must precede external refresh") }) do
      patch(:update)
    end

    assert_response :unprocessable_content
    assert_not_equal "mutated", response.body
    assert_equal 0, @local_session.reload.installed_generation
  ensure
    @controller.allow_forgery_protection = previous
  end

  test "canonical operator activity is unavailable even for an enabled local principal" do
    assert_raises(GovernanceUnavailableError) { @controller.active_operator? }
  end

  test "public session and operator helpers expose the authenticated local RP state" do
    get :helpers

    assert_response :success
    body = response.parsed_body

    assert_equal @local_session.op_session_binding.identity_binding.principal.public_id, body.fetch("current_resource")
    assert_equal @local_session.public_id, body.fetch("current_session")
    assert_equal @local_session.public_id, body.fetch("current_session_public_id")
    assert_equal @local_session.public_id, body.fetch("browser_rp_session_public_id")
    assert body.fetch("browser_rp_controller")
    assert body.fetch("logged_in_operator")
    assert body.fetch("operator")
    assert body.fetch("staff")
    assert_equal "operator", body.fetch("resource_type")
  end

  test "access policy helpers resolve the declared rule and pass its context to policy evaluation" do
    captured = nil
    @controller.stub(
      :allowed_to?,
      ->(rule, context, with:) do
        captured = [rule, context, with]
        true
      end,
    ) do
      get :policy_probe
    end

    assert_response :success
    body = response.parsed_body

    assert_equal "public_strict", body.fetch("mode_policy")
    assert_equal "configured", body.fetch("options").fetch("probe_policy")
    assert_equal :probe_rule, captured.fetch(0)
    assert_equal :public_strict, captured.fetch(1).policy
    assert_equal "configured", captured.fetch(1).options.fetch(:probe_policy)
    assert_equal Authentication::AccessPolicy, captured.fetch(2)
    assert_not body.fetch("current_resource_deactivated")
    assert body.fetch("allowed")
  end

  test "access policy options use the access rule when no authentication mode rule matches" do
    controller_class = @controller.class
    authentication_rules = BrowserRpAuthentication::AUTHENTICATION_MODE_RULES.fetch(controller_class)
    BrowserRpAuthentication::AUTHENTICATION_MODE_RULES[controller_class] = []

    @controller.stub(:allowed_to?, ->(*) { true }) do
      get(:policy_probe)
    end

    assert_response :success
    assert_equal "configured", response.parsed_body.fetch("options").fetch("probe_policy")
  ensure
    BrowserRpAuthentication::AUTHENTICATION_MODE_RULES[controller_class] = authentication_rules
  end

  test "open HTML routes detach a refused credential while JSON routes return unauthorized" do
    cookies.delete(OidcRpBrowserCredentialContract::REFRESH_COOKIE)
    cookies[OidcRpBrowserCredentialContract::ACCESS_COOKIE] = "malformed-access"
    get :open_probe

    assert_response :success
    assert_equal "open", response.body
    assert_empty cookies[OidcRpBrowserCredentialContract::ACCESS_COOKIE].to_s

    cookies.delete(OidcRpBrowserCredentialContract::REFRESH_COOKIE)
    cookies[OidcRpBrowserCredentialContract::ACCESS_COOKIE] = "malformed-access"
    get :open_probe, format: :json

    assert_response :unauthorized
    assert_empty cookies[OidcRpBrowserCredentialContract::ACCESS_COOKIE].to_s
  end

  test "guest mode allows a browser without RP credentials" do
    cookies.delete(OidcRpBrowserCredentialContract::ACCESS_COOKIE)
    cookies.delete(OidcRpBrowserCredentialContract::REFRESH_COOKIE)
    cookies.delete(OidcRpBrowserCredentialContract::SESSION_COOKIE)
    get :guest_probe

    assert_response :success
    assert_equal "guest", response.body
  end

  test "guest mode refuses an authenticated browser RP" do
    get :guest_probe

    assert_response :forbidden
  end

  test "deny-all mode raises even for an authenticated browser RP" do
    error = assert_raises(BrowserRpAuthentication::MissingPolicyError) { get(:deny_all_probe) }

    assert_match(/Denied by default authentication mode/, error.message)
  end

  test "class-level filter skipping delegates ordinary filters and protects access enforcement" do
    Edit::BrowserRpAuthenticationSkipProbeController.skip_probe_filter!

    error =
      assert_raises(BrowserRpAuthentication::SkipNotAllowedError) do
        Edit::BrowserRpAuthenticationSkipProbeController.skip_before_action(:enforce_access_policy!)
      end

    assert_match(/skip_before_action.*enforce_access_policy!/, error.message)
  end

  test "SSO authentication returns for a logged-in RP" do
    get :authenticate_probe

    assert_response :success
    assert_equal "authenticated", response.body
  end

  test "SSO authentication redirects a missing HTML session to sign-in" do
    cookies.delete(OidcRpBrowserCredentialContract::ACCESS_COOKIE)
    cookies.delete(OidcRpBrowserCredentialContract::REFRESH_COOKIE)
    cookies.delete(OidcRpBrowserCredentialContract::SESSION_COOKIE)
    get :authenticate_probe

    assert_response :redirect
    assert_match(%r{/sign\?}, response.headers.fetch("Location"))
  end

  test "SSO authentication answers JSON requests without a session as unauthorized" do
    cookies.delete(OidcRpBrowserCredentialContract::ACCESS_COOKIE)
    cookies.delete(OidcRpBrowserCredentialContract::REFRESH_COOKIE)
    cookies.delete(OidcRpBrowserCredentialContract::SESSION_COOKIE)
    get :authenticate_probe, format: :json

    assert_response :unauthorized
    assert_equal({ "error" => "Unauthorized" }, response.parsed_body)
  end

  test "unsafe request with valid CSRF refreshes once and reaches the same mutation" do
    previous = @controller.allow_forgery_protection
    @controller.allow_forgery_protection = true
    get(:csrf)
    @request.headers["X-CSRF-Token"] = response.body
    @request.headers["Origin"] = request.base_url
    replace_access_claim("exp", 2.minutes.ago.to_i)
    refreshed = rp_cell_test_token_response("edit-org-ww", subject: @payload.fetch("sub"), sid: @payload.fetch("sid"))
    calls = []
    result = OidcOpTokenClient::Result.new(outcome: :success, token_response: refreshed, error: nil)
    OidcOpTokenClient.stub(
      :refresh, ->(**args) {
                  calls << args
                  result
                },
    ) do
      patch(:update)
    end

    assert_response :success
    assert_equal "mutated", response.body
    assert_equal 1, calls.length
    assert_equal 1, @local_session.reload.installed_generation
  ensure
    @controller.allow_forgery_protection = previous
  end

  test "authentication refusal records credential presence without exposing either token" do
    cookies[OidcRpBrowserCredentialContract::ACCESS_COOKIE] = "invalid-access-do-not-log"
    cookies.delete(OidcRpBrowserCredentialContract::REFRESH_COOKIE)
    events = []
    Rails.logger.stub(:info, ->(message) { events << message.to_s }) do
      get :show, params: { required: "1" }
    end

    assert_response :redirect
    event = events.find { |message| message.include?("auth.session.authentication_required") }

    assert event, "the authentication refusal must be observable"
    assert_includes event, "invalid"
    assert_includes event, "access_credential_presented"
    assert_not_includes events.join, "invalid-access-do-not-log"
    assert_not_includes events.join, @tokens.fetch(:refresh_token)
  end

  private

  def replace_access_claim(claim, value)
    payload = @payload.merge(claim => value)
    issuer_id = OidcIssuer.jwt_issuer_id_for_client(OidcClientRegistry.find!("edit-org-ww"))
    token = JitSecurityJwtKeyring.encode(payload, typ: "at+jwt", issuer_id:)
    cookies[OidcRpBrowserCredentialContract::ACCESS_COOKIE] = token
    # Functional tests copy the previous request cookies over the browser jar before dispatch.
    @request.cookies[OidcRpBrowserCredentialContract::ACCESS_COOKIE] = token
  end
end

class BrowserRpAuthenticationDefaultProbeTest < ActionController::TestCase
  self.fixture_table_names = []

  tests Edit::Org::BrowserRpAuthenticationDefaultProbeController

  test "default trust origins are empty and unimplemented RP identity hooks fail explicitly" do
    probe = Edit::Org::BrowserRpAuthenticationDefaultProbeController.new

    assert_equal [], probe.trusted_origins
    assert_raises(NotImplementedError) { probe.client_id_probe }
    assert_raises(NotImplementedError) { probe.resource_type_probe }
  end
end
