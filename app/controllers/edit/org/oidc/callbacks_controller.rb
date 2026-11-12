# typed: false
# frozen_string_literal: true

module Edit
  module Org
    module Oidc
      class CallbacksController < Edit::Org::ApplicationController
        include ::OidcCallback

        AUTHENTICATION_MODE = :open
        declare_authentication_mode! :open

        public

        private

        def oidc_rp_default_landing_path
          "/"
        end

        def oidc_client_id
          "edit-org-ww"
        end
      end
    end
  end
end
