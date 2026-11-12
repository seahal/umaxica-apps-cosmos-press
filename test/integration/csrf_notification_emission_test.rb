# typed: false
# frozen_string_literal: true

# rubocop:disable I18n/RailsI18n/DecorateString

require "test_helper"

# Rails 8.2 instruments CSRF outcomes as ActiveSupport::Notifications events
# (rails/rails#56355): csrf_request_blocked, csrf_javascript_blocked, and
# csrf_token_fallback, all on the .action_controller namespace.
#
# config/initializers/csrf_notifications.rb subscribes CsrfNotificationSubscriber
# to those three names. test/subscribers/csrf_notification_subscriber_test.rb covers
# the subscriber in isolation by handing it a synthetic event, which cannot show that
# Rails actually emits anything here or that the subscription is attached. These tests
# close that gap by driving a real request.
class CsrfNotificationEmissionTest < ActionDispatch::IntegrationTest
  SUBSCRIBED_EVENTS = %w(
    csrf_request_blocked.action_controller
    csrf_javascript_blocked.action_controller
    csrf_token_fallback.action_controller
  ).freeze

  test "the application is subscribed to every CSRF event Rails emits" do
    SUBSCRIBED_EVENTS.each do |event_name|
      assert ActiveSupport::Notifications.notifier.listening?(event_name),
             "Nothing is subscribed to #{event_name}. A CSRF failure would leave no trace."
    end
  end

  test "the subscribed names match the names Rails 8.2 actually instruments" do
    source = Pathname(Gem.loaded_specs.fetch("actionpack").full_gem_path)
      .join("lib/action_controller/metal/request_forgery_protection.rb")

    assert_predicate source, :file?

    instrumented = source.read.scan(/instrument_csrf_event\s+"([^"]+)"/).flatten.uniq

    assert_equal SUBSCRIBED_EVENTS.sort, instrumented.sort,
                 "Rails instruments #{instrumented.inspect} but the initializer subscribes to " \
                 "#{SUBSCRIBED_EVENTS.inspect}. A renamed or added event would go unrecorded."
  end

  # Every phrasing unverified_request_warning_message can produce. Rails'
  # ActionController::LogSubscriber writes payload[:message] verbatim when
  # log_warning_on_csrf_failure is on, which puts an Origin/base_url pair into the log
  # as free text - outside JitLogEvent.format, so ObservabilityRedactor never sees it.
  # config/application.rb turns that off so the redacted event is the only record;
  # config/environments/development.rb turns it back on for local diagnosis.
  FRAMEWORK_WARNING_SHAPES = [
    /\AHTTP Origin header .*didn't match request\.base_url/,
    /\ASec-Fetch-Site header \(cross-site\) indicates a cross-site request/,
    /\ASec-Fetch-Site header is missing or invalid/,
    /\ACan't verify CSRF token authenticity/,
  ].freeze

  RESCUE_FROM_LINE_MARKER = "rescue_from handled"

  test "a cross-site POST is rejected by Edit before Rails CSRF verification" do
    events = nil
    output =
      capture_logs do
        events = capture_csrf_events { post_cross_site_sign_in }
      end

    assert_response :unprocessable_content
    assert_empty events, "Edit's browser request guard rejects cross-site requests before Rails CSRF verification."
    assert_no_match(/csrf-probe@example\.com/, output)
    assert_no_match(/#<ActionDispatch::Request/, output)

    csrf_warning_lines =
      output.lines
        .reject { |line| line.include?(RESCUE_FROM_LINE_MARKER) }
        .select { |line| FRAMEWORK_WARNING_SHAPES.any? { |shape| line.match?(shape) } }

    assert_empty csrf_warning_lines,
                 "A rejected Edit request must not write the unredacted Rails CSRF warning."
  end

  private

  def post_cross_site_sign_in
    host!(Rails.configuration.x.boot_config.fetch(:hosts).edit_staff.host)
    https!
    post(
      "/sign?ri=jp",
      params: { ri: "jp" },
      headers: { "Origin" => "https://attacker.example", "Sec-Fetch-Site" => "cross-site" },
    )
  end

  # Both loggers have to be swapped: the application subscriber writes through
  # Rails.logger, while ActionController::LogSubscriber writes through
  # ActionController::Base.logger, which is captured at boot and does not follow a later
  # reassignment of Rails.logger. Capturing only one would make the "recorded once"
  # assertion pass vacuously.
  def capture_logs
    buffer = StringIO.new
    capture_logger = ActiveSupport::Logger.new(buffer)
    previous_rails_logger = Rails.logger
    previous_controller_logger = ActionController::Base.logger
    Rails.logger = capture_logger
    ActionController::Base.logger = capture_logger

    yield

    buffer.string
  ensure
    Rails.logger = previous_rails_logger
    ActionController::Base.logger = previous_controller_logger
  end

  def capture_csrf_events(&)
    captured = []
    subscriptions =
      SUBSCRIBED_EVENTS.map do |event_name|
        ActiveSupport::Notifications.subscribe(event_name) { |event| captured << event }
      end
    yield
    captured
  ensure
    subscriptions&.each { |subscription| ActiveSupport::Notifications.unsubscribe(subscription) }
  end
end

# rubocop:enable I18n/RailsI18n/DecorateString
