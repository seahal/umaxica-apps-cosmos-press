# frozen_string_literal: true

require "test_helper"

class Edit::Org::Sign::OutsControllerTest < ActionController::TestCase
  self.fixture_table_names = []

  tests Edit::Org::Sign::OutsController

  setup do
    @routes = Rails.application.routes
    @request.host = Rails.configuration.x.boot_config.fetch(:hosts).edit_staff.host
  end

  test "sign-out helpers expose absent local RP state and the current locale" do
    get :edit

    assert_response :success
    view = @controller.view_context

    assert_not view.logged_in?
    assert_nil view.current_resource
    assert_nil view.current_session
    assert_nil view.current_session_public_id
    assert_nil view.browser_rp_session_public_id
    assert_not view.browser_rp_authenticated?
    assert_equal I18n.locale.to_s, view.get_language
  end
end
