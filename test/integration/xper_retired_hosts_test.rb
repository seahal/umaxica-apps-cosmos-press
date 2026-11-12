# typed: false
# frozen_string_literal: true

require "test_helper"

class XperRetiredHostsTest < ActionDispatch::IntegrationTest
  rate_limit_counters!

  RETIRED_HOSTS = %w(
    umaxica.app
    umaxica.com
    umaxica.org
    xper.app.localhost
    xper.com.localhost
    xper.org.localhost
  ).freeze

  REQUESTS = [
    [:get, "/", {}],
    [:get, "/health", {}],
    [:get, "/revision", {}],
    [:get, "/api/v0/health.json", { headers: { "Accept" => "application/json" } }],
    [:get, "/api/v0/revision.json", { headers: { "Accept" => "application/json" } }],
    [:post, "/csp-violation-report", { headers: { "CONTENT_TYPE" => "application/csp-report" } }],
    [:get, "/robots.txt", {}],
    [:get, "/sitemap.xml", {}],
  ].freeze

  RETAINED_INFO_REQUESTS = REQUESTS.reject { |_method, path, _options|
    %w(/ /robots.txt /sitemap.xml).include?(path)
  }.freeze

  SURFACE_CONTROLLER_NAMESPACES = %w(
    docs edit help info news xper
  ).freeze

  test "retired Xper hosts do not reach any surface controller" do
    RETIRED_HOSTS.each do |host|
      REQUESTS.each do |method, path, options|
        host!(host)
        public_send(method, path, **options)

        controller = request.path_parameters[:controller].to_s
        served_by_surface =
          SURFACE_CONTROLLER_NAMESPACES.any? do |namespace|
            controller.start_with?("#{namespace}/")
          end

        assert_not served_by_surface, "#{host} #{method.upcase} #{path} reached #{controller.inspect}"
      end
    end
  end

  test "a retained Info host still owns the same endpoint paths" do
    retained_host = ENV.fetch("PRIVATE_INFO_SERVICE_URL")

    RETAINED_INFO_REQUESTS.each do |method, path, options|
      host!(retained_host)
      public_send(method, path, **options)

      assert_match(/\Ainfo\/app\//, request.path_parameters.fetch(:controller))
      assert_response :success
    end
  end
end
