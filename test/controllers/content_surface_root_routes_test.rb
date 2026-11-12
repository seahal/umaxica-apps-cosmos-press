# typed: false
# frozen_string_literal: true

require "test_helper"

class ContentSurfaceRootRoutesTest < ActionDispatch::IntegrationTest
  self.fixture_table_names = []

  SURFACE_HOSTS = {
    "Docs App" => [
      Rails.configuration.x.boot_config.fetch(:hosts).docs_service.host,
      "docs.jp.umaxica.app",
      "docs.app.localhost",
    ],
    "Docs Com" => [
      Rails.configuration.x.boot_config.fetch(:hosts).docs_corporate.host,
      "docs.jp.umaxica.com",
      "docs.com.localhost",
    ],
    "Docs Org" => [
      Rails.configuration.x.boot_config.fetch(:hosts).docs_staff.host,
      "docs.jp.umaxica.org",
      "docs.org.localhost",
    ],
    "Help App" => [
      Rails.configuration.x.boot_config.fetch(:hosts).help_service.host,
      "help.jp.umaxica.app",
      "help.app.localhost",
    ],
    "Help Com" => [
      Rails.configuration.x.boot_config.fetch(:hosts).help_corporate.host,
      "help.jp.umaxica.com",
      "help.com.localhost",
    ],
    "Help Org" => [
      Rails.configuration.x.boot_config.fetch(:hosts).help_staff.host,
      "help.jp.umaxica.org",
      "help.org.localhost",
    ],
    "Info App" => [
      Rails.configuration.x.boot_config.fetch(:hosts).info_service.host,
      "info.umaxica.app",
      "info.app.localhost",
    ],
    "Info Com" => [
      Rails.configuration.x.boot_config.fetch(:hosts).info_corporate.host,
      "info.umaxica.com",
      "info.com.localhost",
    ],
    "Info Org" => [
      Rails.configuration.x.boot_config.fetch(:hosts).info_staff.host,
      "info.umaxica.org",
      "info.org.localhost",
    ],
    "News App" => [
      Rails.configuration.x.boot_config.fetch(:hosts).news_service.host,
      "news.jp.umaxica.app",
      "news.app.localhost",
    ],
    "News Com" => [
      Rails.configuration.x.boot_config.fetch(:hosts).news_corporate.host,
      "news.jp.umaxica.com",
      "news.com.localhost",
    ],
    "News Org" => [
      Rails.configuration.x.boot_config.fetch(:hosts).news_staff.host,
      "news.jp.umaxica.org",
      "news.org.localhost",
    ],
  }.freeze

  test "content roots return 404 while health remains routed for every host" do
    SURFACE_HOSTS.each do |surface, configured_hosts|
      configured_hosts.compact.uniq.each do |host|
        host! host

        get "/"

        assert_response :not_found, "#{surface} root"

        get "/health"

        assert_response :success, "#{surface} health route"
      end
    end
  end
end
