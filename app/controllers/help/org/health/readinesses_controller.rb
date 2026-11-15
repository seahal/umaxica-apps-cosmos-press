# typed: false
# frozen_string_literal: true

module Help
  module Org
    module Health
      class ReadinessesController < BareController
        include ::HealthCheckRendering

        HealthCheckRendering.configure(self)

        AUTHENTICATION_MODE = :bare
        HEALTH_PROFILE = ::Health::Profiles::Org

        public

        def show
          render_probe(::Health::ReadinessCheck.call(profile: health_profile))
        end
      end
    end
  end
end
