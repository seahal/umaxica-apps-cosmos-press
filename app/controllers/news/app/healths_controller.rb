# typed: false
# frozen_string_literal: true

module News
  module App
    class HealthsController < BareController
      include ::HealthCheckRendering

      HealthCheckRendering.configure(self)

      AUTHENTICATION_MODE = :bare
      HEALTH_PROFILE = ::Health::Profiles::App

      public

      def show
        render_snapshot(::Health::SnapshotCheck.call(profile: health_profile))
      end
    end
  end
end
