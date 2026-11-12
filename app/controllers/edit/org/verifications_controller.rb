# typed: false
# frozen_string_literal: true

module Edit
  module Org
    class VerificationsController < Edit::Org::ApplicationController
      AUTHENTICATION_MODE = :private
      declare_authentication_mode! :private

      public

      def show
        authorize!(current_operator, to: :show?)
        render_step_up_unavailable
      end

      def create
        authorize!(current_operator, to: :show?)
        render_step_up_unavailable
      end

      private

      def render_step_up_unavailable
        response.set_header("Cache-Control", "private, no-store")
        render plain: t("sign.org.verification.step_up_unavailable"), status: :service_unavailable
      end
    end
  end
end
