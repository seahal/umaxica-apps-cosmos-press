# frozen_string_literal: true

require "test_helper"

class RpDeploymentBindingValueTest < ActiveSupport::TestCase
  test "only the owned Edit ORG client has a Press deployment binding" do
    assert_equal ["edit-org-ww"], RpDeploymentBindingValue.active_client_ids
    assert_equal "edit-org-ww", RpDeploymentBindingValue.client_id("edit-org")
    assert_raises(RpDeploymentBindingValue::UnknownRp) { RpDeploymentBindingValue.client_id("core-app") }
    assert_raises(RpDeploymentBindingValue::UnknownRp) { RpDeploymentBindingValue.client_id("base-org") }
    assert_raises(RpDeploymentBindingValue::UnknownRp) { RpDeploymentBindingValue.client_id("tech-org") }
    assert_raises(RpDeploymentBindingValue::UnknownRp) { RpDeploymentBindingValue.client_id("guid-app") }
  end
end
