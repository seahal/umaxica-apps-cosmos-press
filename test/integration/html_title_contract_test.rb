# frozen_string_literal: true

require "test_helper"

class HtmlTitleContractTest < ActionDispatch::IntegrationTest
  BRAND = ENV.fetch("BRAND_NAME").upcase
  FORBIDDEN_WORDS = %w(Auth Base Core Warp Palm Jump Global Rails Inertia API Home).freeze

  RETAINED_ROOTS = [
    [ENV.fetch("PUBLIC_EDIT_STAFF_URL"), "ORG"],
  ].freeze

  NON_HTML_PATH_PATTERNS = [
    %r{\A/health(/(liveness|readiness|startup))?\z},
    %r{\A/\.well-known/},
    %r{\A/(web|edge|api)/v\d},
    %r{\A/csp-violation-report\z},
    %r{\A/revision\z},
    %r{\A/robots\.txt},
    %r{\A/sitemap\.xml\z},
  ].freeze

  test "retained root pages render a branded edition title" do
    RETAINED_ROOTS.each do |host, edition|
      host! host
      get "/", params: { ri: "jp" }

      next if response.redirect?

      assert_response :success, "GET / on #{host}"
      assert_single_html_document
      title = rendered_title

      assert_title_shape(title, edition)
    end
  end

  test "health stays text and is excluded from title contracts" do
    [ENV.fetch("PUBLIC_EDIT_STAFF_URL"), ENV.fetch("PRIVATE_INFO_SERVICE_URL")].each do |host|
      host! host
      get "/health"

      assert_response :success
      assert_equal "text/plain", response.media_type
      assert_match(/\Atitle: Health status\nnamespace: \S+\nstatus: \w+\n/, response.body)
    end

    assert_includes non_html_get_paths, "/health"
  end

  test "the title route inventory discovers HTML and excludes non-HTML endpoints" do
    assert_predicate html_get_paths, :any?, "the HTML route inventory discovered nothing"
    assert_predicate non_html_get_paths, :any?, "expected non-HTML paths to remain excluded"
  end

  private

  def assert_single_html_document
    assert_match %r{\Atext/html}, response.media_type
    assert_equal 1, css_select("html").size, "expected exactly one <html> element"
    assert_equal 1, css_select("head").size, "expected exactly one <head> element"
    assert_equal 1, css_select("title").size, "expected exactly one <title> element"
  end

  def rendered_title
    css_select("title").first&.text.to_s
  end

  def static_get_paths
    Rails.application.routes.routes
      .select { |route| route.verb == "GET" }
      .map { |route| route.path.spec.to_s.sub(/\(\.:format\)\z/, "") }
      .reject { |path| path.include?(":") || path.include?("*") }
      .uniq
  end

  def non_html_get_paths
    static_get_paths.select { |path| NON_HTML_PATH_PATTERNS.any? { |pattern| pattern.match?(path) } }
  end

  def html_get_paths
    static_get_paths - non_html_get_paths
  end

  def assert_title_shape(title, edition)
    assert_predicate title.strip, :present?, "title must not be blank"
    assert_includes title, "#{BRAND} (#{edition})", "title must carry the brand and edition"
    assert_not_includes title, "Umaxica", "brand must be upper case"
    assert_not_includes title, "translation missing"
    assert_not_includes title, "|", "the separator is an EM DASH, not a pipe"

    FORBIDDEN_WORDS.each do |word|
      assert_no_match(/\b#{word}\b/, title, "#{title.inspect} leaks #{word}")
    end
  end
end
