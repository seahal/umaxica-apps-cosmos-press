# typed: false
# frozen_string_literal: true

module News
  module App
    module Health
      class ReadinessesController < BareController
        include ::HealthCheckRendering

        HealthCheckRendering.configure(self)

        AUTHENTICATION_MODE = :bare
        HEALTH_PROFILE = ::Health::Profiles::App

        public

        def show
          render_probe(::Health::ReadinessCheck.call(profile: health_profile))
        end
      end
    end
  end
end
