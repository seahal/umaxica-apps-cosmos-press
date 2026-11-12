# typed: false
# frozen_string_literal: true

module Authentication
  # Request admission includes anonymous Sign/public requests. Session capability checks belong
  # to domain policies after authentication, not to these unchanged admission predicates.
  class AccessPolicy < ActionPolicy::Base
    authorize :user, optional: true

    def public_strict?
      true
    end

    def auth_required?
      record.logged_in
    end

    def guest_only?
      !record.logged_in || record.current_resource_deactivated
    end
  end
end
