# typed: false
# frozen_string_literal: true

require "test_helper"

class BranchCoverageBatch28ConcernEasyArmsTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "SignErrorResponses null Origin classification" do
    helper = Class.new(ApplicationController) { include SignErrorResponses }.new
    request = ActionDispatch::TestRequest.create
    request.headers["Origin"] = "null"
    helper.set_request!(request)
    helper.set_response!(ActionDispatch::TestResponse.new)

    assert_not helper.respond_to?(:csrf_failure_reason, true)
    assert_not helper.respond_to?(:reject_csrf!, true)
  end

  test "PublishingManagementCell class methods raise without constants on concrete controller" do
    anon =
      Class.new do
        def self.name = "Anon/Publishing/EntriesController"
        extend PublishingManagementCell::ClassMethods
      end

    assert_raises(NameError) { anon.publishing_audience }
  end
end
