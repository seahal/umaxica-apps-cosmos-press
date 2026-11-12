# frozen_string_literal: true

require "test_helper"

class ProcessorErasureNotificationAdapterRegistryTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "returns the configured adapter and reports an unconfigured processor as absent" do
    adapter = Object.new

    Rails.application.config.x.stub(:processor_erasure_notification_adapters, { "processor_1" => adapter }) do
      assert_same adapter, ProcessorErasureNotificationAdapterRegistry.fetch(:processor_1)
      assert_nil ProcessorErasureNotificationAdapterRegistry.fetch(:unknown_processor)
    end
  end
end
