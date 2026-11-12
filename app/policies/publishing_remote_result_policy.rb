# typed: false
# frozen_string_literal: true

# RP-side record of the Publishing authority's own decision (R5-WU13). The Edit RP never decides
# Publishing access itself; it only refuses to render when the authority answered forbidden or
# unauthenticated, so verify_authorized still holds for every private CMS action.
class PublishingRemoteResultPolicy < ApplicationPolicy
  public

  def show?
    return false unless record.is_a?(PublishingAuthorityClient::Result)

    case record.status
    when :ok, :not_found, :unprocessable
      true
    when :forbidden, :unauthorized
      false
    when :dependency
      raise GovernanceUnavailableError, "Publishing authority is unavailable"
    else
      raise ArgumentError, "unsupported Publishing authority outcome"
    end
  end
end
