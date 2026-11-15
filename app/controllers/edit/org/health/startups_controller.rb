# typed: false
# frozen_string_literal: true

module Edit
  module Org
    module Health
      class StartupsController < BareController
        include ::HealthCheckRendering

        HealthCheckRendering.configure(self)

        AUTHENTICATION_MODE = :bare
        HEALTH_PROFILE = ::Health::Profiles::EditOrg

        public

        def show
          render_probe(::Health::StartupCheck.call(profile: health_profile))
        end
      end
    end
  end
end
