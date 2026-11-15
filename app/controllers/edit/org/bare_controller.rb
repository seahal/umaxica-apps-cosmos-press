# typed: false
# frozen_string_literal: true

module Edit
  module Org
    class BareController < ActionController::Base
      include ::FqdnAvailabilityGate

      FqdnAvailabilityGate.configure(self)
      include ::RateLimit
      include ::DefaultNoStore

      rescue_from RequestContextContract::InvalidRegionError, with: -> { head :bad_request }

      AUTHENTICATION_MODE = :bare

      helper_method :get_language

      prepend_before_action :apply_default_no_store

      allow_browser versions: :modern

      protect_from_forgery using: :header_or_legacy_token, with: :exception

      private

      def get_language = I18n.locale.to_s
    end
  end
end
