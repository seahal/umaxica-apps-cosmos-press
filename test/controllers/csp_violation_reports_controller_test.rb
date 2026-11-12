# typed: false
# frozen_string_literal: true

require "test_helper"
# require "helpers/global_test_support"

class CspViolationReportsControllerTest < ActionDispatch::IntegrationTest
  # Rate-limit counters are a NullStore by default in test so unrelated tests
  # cannot accumulate them; this file asserts real limiting behavior, so it
  # opts into a deterministic MemoryStore.
  rate_limit_counters!

  setup { clear_rate_limit_store }
  teardown { clear_rate_limit_store }

  test "routes record CSP violations for representative surfaces through Rails event" do
    events = []

    Rails.event.stub(:notify, ->(name, payload) { events << [name, payload] }) do
      csp_report_cases.each do |host, helper_name|
        host!(host)

        post public_send(helper_name), params: csp_report_payload, as: :json

        assert_response :no_content
      end
    end

    assert_equal csp_report_cases.size, events.size
    assert events.all? { |name, _payload| name == CspViolationReportIntake::EVENT_NAME }
    assert events.all? { |_name, payload| payload[:category] == "application" }
    assert events.all? { |_name, payload| payload[:blocked_uri] == "https://cdn.example.test/script.js" }
    assert events.all? { |_name, payload| payload[:script_sample].nil? }
  end

  test "post without csrf token returns no content" do
    with_forgery_protection do
      host! ENV.fetch("PRIVATE_INFO_SERVICE_URL")

      post info_app_csp_violation_report_path,
           params: csp_report_payload.to_json,
           headers: {
             "CONTENT_TYPE" => "application/csp-report",
           }
    end

    assert_response :no_content
  end

  test "accepts CSP report with Origin null when forgery protection is enabled" do
    with_forgery_protection do
      host! ENV.fetch("PRIVATE_INFO_SERVICE_URL")

      post info_app_csp_violation_report_path,
           params: csp_report_payload.to_json,
           headers: {
             "CONTENT_TYPE" => "application/csp-report",
             "HTTP_ORIGIN" => "null",
           }
    end

    assert_response :no_content
  end

  test "application csp report content type returns no content" do
    host! ENV.fetch("PRIVATE_INFO_SERVICE_URL")

    post info_app_csp_violation_report_path,
         params: csp_report_payload.to_json,
         headers: { "CONTENT_TYPE" => "application/csp-report" }

    assert_response :no_content
  end

  test "application json content type returns no content" do
    host! ENV.fetch("PRIVATE_INFO_SERVICE_URL")

    post info_app_csp_violation_report_path,
         params: csp_report_payload.to_json,
         headers: { "CONTENT_TYPE" => "application/json" }

    assert_response :no_content
  end

  test "malformed JSON still returns no content and does not record an event" do
    host! ENV.fetch("PRIVATE_INFO_SERVICE_URL")

    events = []
    Rails.event.stub(:notify, ->(name, payload) { events << [name, payload] }) do
      post info_app_csp_violation_report_path, params: "{not valid json", headers: json_headers

      assert_response :no_content
    end

    assert_empty events
  end

  test "oversized content length returns no content without calling intake" do
    host! ENV.fetch("PRIVATE_INFO_SERVICE_URL")

    called = false
    CspViolationReportIntake.stub(:call, ->(**) { called = true }) do
      post info_app_csp_violation_report_path,
           params: "",
           headers: {
             "CONTENT_TYPE" => "application/csp-report",
             "CONTENT_LENGTH" => (CspViolationReportIntake::MAX_BODY_BYTES + 1).to_s,
           }
    end

    assert_response :no_content
    assert_not called
  end

  test "rate limit overflow still returns no content without recording the over-limit report" do
    host! ENV.fetch("PRIVATE_INFO_SERVICE_URL")
    events = []

    Rails.event.stub(:notify, ->(name, _payload) { events << name }) do
      120.times do
        post info_app_csp_violation_report_path, params: csp_report_payload, as: :json
      end

      assert_equal 120, events.count(CspViolationReportIntake::EVENT_NAME)

      post info_app_csp_violation_report_path, params: csp_report_payload, as: :json
    end

    assert_response :no_content
    assert_equal 120, events.count(CspViolationReportIntake::EVENT_NAME)
  end

  test "controller calls intake but does not call subscriber directly" do
    host! ENV.fetch("PRIVATE_INFO_SERVICE_URL")

    called = false
    CspViolationReportIntake.stub(:call, ->(**) { called = true }) do
      CspViolationSubscriber.stub(
        :new,
        -> { raise RuntimeError, "subscriber must not be instantiated by controller" },
      ) do
        post info_app_csp_violation_report_path, params: csp_report_payload, as: :json
      end
    end

    assert_response :no_content
    assert called
  end

  test "ordinary state-changing endpoint still rejects tokenless post when forgery protection is enabled" do
    host! ENV.fetch("PUBLIC_EDIT_STAFF_URL")

    with_forgery_protection do
      # This is explicitly a cross-site request without a token.
      post "/sign", params: { ri: "jp" }, headers: { "Sec-Fetch-Site" => "cross-site" }
    end

    assert_response :unprocessable_content
  end

  private

  def csp_report_cases
    csp_report_edit_cases + csp_report_content_cases
  end

  def csp_report_edit_cases
    [[ENV.fetch("PUBLIC_EDIT_STAFF_URL"), :edit_org_csp_violation_report_path]]
  end

  def csp_report_content_cases
    [
      [ENV.fetch("PRIVATE_DOCS_SERVICE_URL"), :docs_app_csp_violation_report_path],
      [ENV.fetch("PRIVATE_DOCS_CORPORATE_URL"), :docs_com_csp_violation_report_path],
      [ENV.fetch("PRIVATE_DOCS_STAFF_URL"), :docs_org_csp_violation_report_path],
      [ENV.fetch("PRIVATE_HELP_SERVICE_URL"), :help_app_csp_violation_report_path],
      [ENV.fetch("PRIVATE_HELP_CORPORATE_URL"), :help_com_csp_violation_report_path],
      [ENV.fetch("PRIVATE_HELP_STAFF_URL"), :help_org_csp_violation_report_path],
      [ENV.fetch("PRIVATE_NEWS_SERVICE_URL"), :news_app_csp_violation_report_path],
      [ENV.fetch("PRIVATE_NEWS_CORPORATE_URL"), :news_com_csp_violation_report_path],
      [ENV.fetch("PRIVATE_NEWS_STAFF_URL"), :news_org_csp_violation_report_path],
      [ENV.fetch("PRIVATE_INFO_SERVICE_URL"), :info_app_csp_violation_report_path],
      [ENV.fetch("PRIVATE_INFO_CORPORATE_URL"), :info_com_csp_violation_report_path],
      [ENV.fetch("PRIVATE_INFO_STAFF_URL"), :info_org_csp_violation_report_path],
    ]
  end

  def csp_report_payload
    {
      "csp-report" => {
        "document-uri" => "https://app.example.test/settings?token=secret#fragment",
        "blocked-uri" => "https://cdn.example.test/script.js?session=secret#inline",
        "effective-directive" => "script-src",
        "script-sample" => "secret inline sample",
      },
    }
  end

  def json_headers
    { "CONTENT_TYPE" => "application/json" }
  end

  def clear_rate_limit_store
    Rails.configuration.x.rate_limit.fetch(:store).clear
  end

  def with_forgery_protection
    previous = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    yield
  ensure
    ActionController::Base.allow_forgery_protection = previous
  end
end
