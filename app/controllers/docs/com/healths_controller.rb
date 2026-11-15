# typed: false
# frozen_string_literal: true

module Docs
  module Com
    class HealthsController < BareController
      include ::HealthCheckRendering

      HealthCheckRendering.configure(self)

      AUTHENTICATION_MODE = :bare
      HEALTH_PROFILE = ::Health::Profiles::Com

      public

      def show
        render_snapshot(::Health::SnapshotCheck.call(profile: health_profile))
      end
    end
  end
end
