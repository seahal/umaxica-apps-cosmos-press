# typed: false
# frozen_string_literal: true

require "test_helper"

class JumpRtSurfaceIdentityTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "Press has no local Jump issuer capability" do
    assert_empty JumpRtSurface::ISSUER_ORIGIN_ENV
    assert_empty JumpRtSurface::ISSUER_NAMESPACES
  end

  test "owned and unknown namespaces cannot acquire local Jump issuer authority" do
    ["EDIT_ORG", "DOCS_APP", "unknown", nil, "", "0", "EDIT_ORG\0"].each do |namespace|
      assert_raises(JumpRtConfigurationError) { JumpRtSurface.normalize_namespace(namespace) }
      assert_raises(JumpRtConfigurationError) { JumpRtSurface.issuer_origin(namespace) }
      assert_raises(JumpRtConfigurationError) { JumpRtSurface.issuer_jwks_uri(namespace) }
    end
  end

  test "owned Press controllers cannot issue Jump tokens" do
    %w(
      Edit::Org::Publishing::Docs::EntriesController
      Docs::App::RevisionsController
      Help::Com::HealthsController
      Info::Org::RevisionsController
      News::App::Api::V0::EntriesController
    ).each do |controller|
      assert_raises(JumpRtConfigurationError) { JumpRtSurface.namespace_for_controller(controller) }
    end
  end
end
