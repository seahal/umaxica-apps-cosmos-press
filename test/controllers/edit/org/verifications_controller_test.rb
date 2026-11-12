# typed: false
# frozen_string_literal: true

require "test_helper"

module Edit
  module Org
    class VerificationActionProbeController < VerificationsController
      AUTHENTICATION_MODE = :deny_all

      declare_authentication_mode! :private, only: %i(show create)
      declare_authentication_mode! :open, only: :csrf

      def csrf
        render plain: form_authenticity_token
      end
    end
  end
end

class Edit::Org::VerificationsControllerTest < ActionController::TestCase
  include RpCellSessionHelper

  self.fixture_table_names = []

  tests Edit::Org::VerificationActionProbeController

  setup do
    @routes = ActionDispatch::Routing::RouteSet.new
    @routes.draw do
      get "/csrf" => "edit/org/verification_action_probe#csrf"
      get "/verifications" => "edit/org/verification_action_probe#show"
      post "/verifications" => "edit/org/verification_action_probe#create"
    end
    @request.host = Rails.configuration.x.boot_config.fetch(:hosts).edit_staff.host
    @previous_jwks_clients = OidcOpJwksClient::CLIENTS.dup
    install_rp_cell_operator_jwks_client!
    @tokens, @payload, @local_session = sign_in_edit_rp
  end

  teardown do
    OidcOpJwksClient::CLIENTS.clear
    @previous_jwks_clients.each { |key, value| OidcOpJwksClient::CLIENTS[key] = value }
  end

  test "authenticated step-up page remains explicitly unavailable" do
    get :show

    assert_response :service_unavailable
    assert_equal I18n.t("sign.org.verification.step_up_unavailable"), response.body
  end

  test "authenticated step-up submission remains explicitly unavailable" do
    get :csrf
    @request.headers["Origin"] = @request.base_url
    @request.headers["X-CSRF-Token"] = response.body

    post :create

    assert_response :service_unavailable
    assert_equal I18n.t("sign.org.verification.step_up_unavailable"), response.body
  end
end
