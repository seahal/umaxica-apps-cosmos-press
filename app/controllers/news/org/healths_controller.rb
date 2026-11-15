# typed: false
# frozen_string_literal: true

module News
  module Org
    class HealthsController < BareController
      include ::HealthCheckRendering

      HealthCheckRendering.configure(self)

      AUTHENTICATION_MODE = :bare
      HEALTH_PROFILE = ::Health::Profiles::Org

      public

      def show
        render_snapshot(::Health::SnapshotCheck.call(profile: health_profile))
      end
    end
  end
end
