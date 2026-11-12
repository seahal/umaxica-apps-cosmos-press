# frozen_string_literal: true

require "test_helper"

class ProtocolControllerCsrfBoundaryTest < ActiveSupport::TestCase
  EDIT_RP_CALLBACK = Edit::Org::Oidc::CallbacksController

  test "the Edit OIDC callback retains browser session CSRF protection" do
    assert_operator EDIT_RP_CALLBACK, :<, ActionController::RequestForgeryProtection
    assert_includes EDIT_RP_CALLBACK._process_action_callbacks.map(&:filter), :verify_authenticity_token
  end
end
