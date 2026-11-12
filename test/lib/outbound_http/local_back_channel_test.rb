# frozen_string_literal: true

require "test_helper"

class LocalBackChannelTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "external Access and Governance destinations retain scheme host port path and query" do
    hosts = Rails.configuration.x.boot_config.fetch(:hosts)
    ENV.delete("PORT")
    [hosts.visa_service.host, hosts.visa_staff.host, hosts.base_service.host, hosts.base_staff.host].each do |host|
      url = "https://#{host}:8443/provider/path?scope=openid"

      assert_equal url, OutboundHttp::LocalBackChannel.url(url)
      assert OutboundHttp::LocalBackChannel.require_https?(url)
    end
  end

  test "the owned Edit origin alone maps to the configured local HTTP port" do
    host = Rails.configuration.x.boot_config.fetch(:hosts).edit_staff.host
    ENV["PORT"] = "4567"
    public_url = "https://#{host}:8443/api/v0/publishing?locale=ja"
    local_url = "http://#{host}:4567/api/v0/publishing?locale=ja"

    assert_equal local_url, OutboundHttp::LocalBackChannel.url(public_url)
    assert_not OutboundHttp::LocalBackChannel.require_https?(local_url)
    assert OutboundHttp::LocalBackChannel.require_https?("http://#{host}:4568/api/v0/publishing")
    assert OutboundHttp::LocalBackChannel.require_https?("http://user@#{host}:4567/api/v0/publishing")
    assert OutboundHttp::LocalBackChannel.require_https?("http://external.example:4567/api/v0/publishing")
  end

  test "local Edit routing accepts both valid port boundaries and refuses neighboring invalid ports" do
    host = Rails.configuration.x.boot_config.fetch(:hosts).edit_staff.host
    [1, 65_535].each do |port|
      ENV["PORT"] = port.to_s

      assert_equal "http://#{host}:#{port}/owned", OutboundHttp::LocalBackChannel.url("https://#{host}/owned")
    end
    ["0", "65536", "invalid", "", "1.5"].each do |port|
      ENV["PORT"] = port

      assert_raises(ArgumentError) { OutboundHttp::LocalBackChannel.url("https://#{host}/owned") }
    end
    ENV.delete("PORT")

    assert_raises(KeyError) { OutboundHttp::LocalBackChannel.url("https://#{host}/owned") }
  end
end
