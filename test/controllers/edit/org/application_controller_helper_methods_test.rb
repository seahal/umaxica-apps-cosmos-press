# frozen_string_literal: true

require "test_helper"

module Edit
  module Org
    class HelperMethodProbeController < ApplicationController
      AUTHENTICATION_MODE = :open

      def show
        render plain: "probe"
      end
    end
  end
end

class Edit::Org::ApplicationControllerHelperMethodsTest < ActionController::TestCase
  self.fixture_table_names = []

  tests Edit::Org::HelperMethodProbeController

  setup do
    @routes = ActionDispatch::Routing::RouteSet.new
    @routes.draw do
      get "/probe" => "edit/org/helper_method_probe#show"
    end
    @request.host = Rails.configuration.x.boot_config.fetch(:hosts).edit_staff.host
  end

  test "application helpers expose local session state and fail closed for Governance state" do
    get :show

    assert_response :success
    view = @controller.view_context

    assert_nil view.current_resource
    assert_nil view.current_session
    assert_nil view.current_session_public_id
    assert_nil view.browser_rp_session_public_id
    assert_not view.browser_rp_authenticated?
    assert_not view.logged_in_operator?
    assert_raises(GovernanceUnavailableError) { view.active_operator? }
  end
end
