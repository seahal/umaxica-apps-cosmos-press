# typed: false
# frozen_string_literal: true

module Info
  module Org
    module Health
      class LivenessesController < BareController
        include ::HealthCheckRendering

        HealthCheckRendering.configure(self)

        AUTHENTICATION_MODE = :bare
        HEALTH_PROFILE = ::Health::Profiles::Org

        public

        def show
          render_probe(::Health::LivenessCheck.call(profile: health_profile))
        end
      end
    end
  end
end
