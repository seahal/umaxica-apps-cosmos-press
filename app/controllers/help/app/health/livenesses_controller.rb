# typed: false
# frozen_string_literal: true

module Help
  module App
    module Health
      class LivenessesController < BareController
        include ::HealthCheckRendering

        HealthCheckRendering.configure(self)

        AUTHENTICATION_MODE = :bare
        HEALTH_PROFILE = ::Health::Profiles::App

        public

        def show
          render_probe(::Health::LivenessCheck.call(profile: health_profile))
        end
      end
    end
  end
end
