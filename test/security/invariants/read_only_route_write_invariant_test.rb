# typed: false
# frozen_string_literal: true

require "test_helper"

module Security
  module Invariants
    class ReadOnlyRouteWriteInvariantTest < ActionDispatch::IntegrationTest
      test "ordinary Info health GET does not write persistent state" do
        observed_writes = []

        callback =
          lambda do |_name, _started, _finished, _unique_id, payload|
            sql = payload[:sql].to_s.squish
            next unless sql.match?(/\A(?:INSERT|UPDATE|DELETE)\b/i)
            next if sql.match?(/\A(?:INSERT|UPDATE|DELETE)\s+"?ar_internal_metadata"?\b/i)
            next if sql.match?(/\A(?:INSERT|UPDATE|DELETE)\s+"?schema_migrations"?\b/i)

            observed_writes << sql
          end

        reset!
        host! "info.app.localhost"

        ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
          get "/health"
        end

        assert_response :success
        assert_empty observed_writes, "Info health reads must not persist state"
      end
    end
  end
end
