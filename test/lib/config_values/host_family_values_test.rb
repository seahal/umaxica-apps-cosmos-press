# typed: false
# frozen_string_literal: true

require "test_helper"
# require "helpers/global_test_support"
require Rails.root.join("lib/config_values_origin_value").to_s
require Rails.root.join("lib/config_values_host_family_values").to_s

class ConfigValuesHostFamilyValuesTest < ActiveSupport::TestCase
  LOCAL_HOST_ENV = {
    "PUBLIC_AUTH_SERVICE_URL" => "sign.app.localhost",
    "PUBLIC_AUTH_STAFF_URL" => "sign.org.localhost",
    "PUBLIC_BASE_SERVICE_URL" => "www.umaxica.app",
    "PUBLIC_BASE_CORPORATE_URL" => "www.umaxica.com",
    "PUBLIC_BASE_STAFF_URL" => "www.umaxica.org",
    "PUBLIC_VISA_SERVICE_URL" => "visa.app.localhost",
    "PUBLIC_VISA_STAFF_URL" => "visa.org.localhost",
    "PRIVATE_HELP_SERVICE_URL" => "help.app.localhost",
    "PRIVATE_HELP_CORPORATE_URL" => "help.com.localhost",
    "PRIVATE_HELP_STAFF_URL" => "help.org.localhost",
    "PRIVATE_INFO_SERVICE_URL" => "info.app.localhost",
    "PRIVATE_INFO_CORPORATE_URL" => "info.com.localhost",
    "PRIVATE_INFO_STAFF_URL" => "info.org.localhost",
    "PRIVATE_DOCS_SERVICE_URL" => "docs.app.localhost",
    "PRIVATE_DOCS_CORPORATE_URL" => "docs.com.localhost",
    "PRIVATE_DOCS_STAFF_URL" => "docs.org.localhost",
    "PRIVATE_NEWS_SERVICE_URL" => "news.app.localhost",
    "PRIVATE_NEWS_CORPORATE_URL" => "news.com.localhost",
    "PRIVATE_NEWS_STAFF_URL" => "news.org.localhost",
    "EDIT_STAFF_URL" => "edit.org.localhost",
  }.freeze

  test "non-production host families use explicit environment values" do
    values = ConfigValues::HostFamilyValues.build(env: LOCAL_HOST_ENV, production: false)

    assert_equal "https://sign.app.localhost", values.sign_service.to_s
    assert_equal "https://sign.org.localhost", values.sign_staff.to_s

    assert_equal "https://www.umaxica.app", values.base_service.to_s
    assert_equal "https://www.umaxica.com", values.base_corporate.to_s
    assert_equal "https://www.umaxica.org", values.base_staff.to_s

    assert_equal "https://visa.app.localhost", values.visa_service.to_s
    assert_equal "https://visa.org.localhost", values.visa_staff.to_s

    assert_equal "https://help.app.localhost", values.help_service.to_s
    assert_equal "https://help.com.localhost", values.help_corporate.to_s
    assert_equal "https://help.org.localhost", values.help_staff.to_s

    assert_equal "https://info.app.localhost", values.info_service.to_s
    assert_equal "https://info.com.localhost", values.info_corporate.to_s
    assert_equal "https://info.org.localhost", values.info_staff.to_s
  end

  test "origin helpers retain only the used content and Auth host groups" do
    values = ConfigValues::HostFamilyValues.build(env: LOCAL_HOST_ENV, production: false)

    assert_equal 3, values.info_origins.size
    assert_equal [values.info_service, values.info_corporate, values.info_staff], values.info_origins

    assert_equal values.sign_service, values.auth_service
    assert_equal values.sign_staff, values.auth_staff
    assert_equal values.base_service, values.base_for_resource_type("client")
    assert_equal values.base_staff, values.base_for_resource_type("operator")
    assert_equal values.base_staff, values.base_for_resource_type("staff")
    assert_equal [values.docs_service, values.docs_corporate, values.docs_staff], values.docs_origins
    assert_equal [values.news_service, values.news_corporate, values.news_staff], values.news_origins
    assert_raises(ArgumentError) { values.base_for_resource_type("visitor") }
  end

  test "build in production mode resolves explicitly configured host values" do
    env = {
      "AUTH_SERVICE_URL" => "sign.example.test",
      "AUTH_STAFF_URL" => "sign-org.example.test",
      "BASE_SERVICE_URL" => "base.example.test",
      "BASE_CORPORATE_URL" => "base-com.example.test",
      "BASE_STAFF_URL" => "base-org.example.test",
      "VISA_SERVICE_URL" => "visa.example.test",
      "VISA_STAFF_URL" => "visa-org.example.test",
      "HELP_SERVICE_URL" => "help.example.test",
      "HELP_CORPORATE_URL" => "help-com.example.test",
      "HELP_STAFF_URL" => "help-org.example.test",
      "INFO_SERVICE_URL" => "info.example.test",
      "INFO_CORPORATE_URL" => "info-com.example.test",
      "INFO_STAFF_URL" => "info-org.example.test",
      "PRIVATE_DOCS_SERVICE_URL" => "docs.example.test",
      "PRIVATE_DOCS_CORPORATE_URL" => "docs-com.example.test",
      "PRIVATE_DOCS_STAFF_URL" => "docs-org.example.test",
      "PRIVATE_NEWS_SERVICE_URL" => "news.example.test",
      "PRIVATE_NEWS_CORPORATE_URL" => "news-com.example.test",
      "PRIVATE_NEWS_STAFF_URL" => "news-org.example.test",
      "EDIT_STAFF_URL" => "edit-org.example.test",
    }
    values = ConfigValues::HostFamilyValues.build(env: env, production: true)

    assert_equal "https://sign-org.example.test", values.sign_staff.to_s
    assert_equal "https://info-org.example.test", values.info_staff.to_s
    assert_equal "https://visa.example.test", values.visa_service.to_s
    assert_equal "https://edit-org.example.test", values.edit_staff.to_s
  end

  test "build in production mode raises KeyError when a required ENV key is missing" do
    assert_raises(KeyError) do
      ConfigValues::HostFamilyValues.build(env: {}, production: true)
    end
  end

  test "base origins use PUBLIC_BASE_*_URL when BASE_*_URL is absent" do
    env = {
      "PUBLIC_BASE_SERVICE_URL" => "www.umaxica.app",
      "PUBLIC_BASE_CORPORATE_URL" => "www.umaxica.com",
      "PUBLIC_BASE_STAFF_URL" => "www.umaxica.org",
    }
    values = ConfigValues::HostFamilyValues.build(env: LOCAL_HOST_ENV.merge(env), production: false)

    assert_equal "www.umaxica.app", values.base_service.host
    assert_equal "www.umaxica.com", values.base_corporate.host
    assert_equal "www.umaxica.org", values.base_staff.host
  end

  test "BASE_*_URL takes precedence over PUBLIC_BASE_*_URL for base origins" do
    env = {
      "BASE_SERVICE_URL" => "base.umaxica.app",
      "BASE_CORPORATE_URL" => "base.umaxica.com",
      "BASE_STAFF_URL" => "base.umaxica.org",
      "PUBLIC_BASE_SERVICE_URL" => "www.umaxica.app",
      "PUBLIC_BASE_CORPORATE_URL" => "www.umaxica.com",
      "PUBLIC_BASE_STAFF_URL" => "www.umaxica.org",
    }
    values = ConfigValues::HostFamilyValues.build(env: LOCAL_HOST_ENV.merge(env), production: false)

    assert_equal "base.umaxica.app", values.base_service.host
    assert_equal "base.umaxica.com", values.base_corporate.host
    assert_equal "base.umaxica.org", values.base_staff.host
  end

  test "Auth service and staff use PUBLIC_AUTH_*_URL when AUTH_*_URL is absent" do
    env = {
      "PUBLIC_AUTH_SERVICE_URL" => "auth.umaxica.app",
      "PUBLIC_AUTH_STAFF_URL" => "auth.umaxica.org",
    }
    values = ConfigValues::HostFamilyValues.build(env: LOCAL_HOST_ENV.merge(env), production: false)

    assert_equal "auth.umaxica.app", values.sign_service.host
    assert_equal "auth.umaxica.org", values.sign_staff.host
  end

  test "help and info origins use their explicit private values when public values also exist" do
    env = {
      "PUBLIC_HELP_SERVICE_URL" => "help.umaxica.app",
      "PUBLIC_INFO_SERVICE_URL" => "info.umaxica.app",
    }
    values = ConfigValues::HostFamilyValues.build(env: LOCAL_HOST_ENV.merge(env), production: false)

    assert_equal "help.app.localhost", values.help_service.host
    assert_equal "info.app.localhost", values.info_service.host
  end

  test "AUTH_*_URL takes precedence over PUBLIC_AUTH_*_URL for sign origins" do
    env = {
      "AUTH_SERVICE_URL" => "sign.example.test",
      "PUBLIC_AUTH_SERVICE_URL" => "auth.umaxica.app",
    }
    values = ConfigValues::HostFamilyValues.build(env: LOCAL_HOST_ENV.merge(env), production: false)

    assert_equal "sign.example.test", values.sign_service.host
  end

  test "origin adds an https scheme when the raw value lacks one" do
    env = {
      "AUTH_SERVICE_URL" => "https://sign.example.test",
      "AUTH_STAFF_URL" => "sign-org.example.test",
      "BASE_SERVICE_URL" => "base.example.test",
      "BASE_CORPORATE_URL" => "base-com.example.test",
      "BASE_STAFF_URL" => "base-org.example.test",
      "VISA_SERVICE_URL" => "visa.example.test",
      "VISA_STAFF_URL" => "visa-org.example.test",
      "HELP_SERVICE_URL" => "help.example.test",
      "HELP_CORPORATE_URL" => "help-com.example.test",
      "HELP_STAFF_URL" => "help-org.example.test",
      "INFO_SERVICE_URL" => "info.example.test",
      "INFO_CORPORATE_URL" => "info-com.example.test",
      "INFO_STAFF_URL" => "info-org.example.test",
      "PRIVATE_DOCS_SERVICE_URL" => "docs.example.test",
      "PRIVATE_DOCS_CORPORATE_URL" => "docs-com.example.test",
      "PRIVATE_DOCS_STAFF_URL" => "docs-org.example.test",
      "PRIVATE_NEWS_SERVICE_URL" => "news.example.test",
      "PRIVATE_NEWS_CORPORATE_URL" => "news-com.example.test",
      "PRIVATE_NEWS_STAFF_URL" => "news-org.example.test",
      "EDIT_STAFF_URL" => "edit-org.example.test",
    }
    values = ConfigValues::HostFamilyValues.build(env: env, production: true)

    assert_equal "https://sign.example.test", values.sign_service.to_s
    assert_equal "https://help.example.test", values.help_service.to_s
    assert_equal "https://info.example.test", values.info_service.to_s
  end
end
