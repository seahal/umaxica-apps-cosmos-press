# typed: false
# frozen_string_literal: true

require "test_helper"

class OutboundEmailSuspensionInterceptorTest < ActiveSupport::TestCase
  DeliveryHandler = Struct.new(:name)
  Message = Struct.new(:delivery_handler, :perform_deliveries)

  test "disables delivery and logs only the mailer classification when suspended" do
    message = Message.new(DeliveryHandler.new("Store::PromotionalMailer"), true)
    warnings = []
    channels = []

    OutboundChannelSuspension.stub(
      :suspended?,
      ->(channel) do
        channels << channel
        true
      end,
    ) do
      Rails.logger.stub(:warn, ->(warning) { warnings << warning }) do
        OutboundEmailSuspensionInterceptor.delivering_email(message)
      end
    end

    assert_equal [:promotional_email], channels
    assert_not message.perform_deliveries
    assert_equal 1, warnings.length
    assert_includes warnings.first, "outbound.email.suspended"
    assert_includes warnings.first, "PromotionalMailer"
  end

  test "leaves delivery enabled when the channel is not suspended" do
    message = Message.new(DeliveryHandler.new("Store::TransactionalMailer"), true)

    OutboundChannelSuspension.stub(:suspended?, false) do
      OutboundEmailSuspensionInterceptor.delivering_email(message)
    end

    assert message.perform_deliveries
  end
end
