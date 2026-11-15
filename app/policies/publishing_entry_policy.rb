# typed: false
# frozen_string_literal: true

# A local RP credential establishes authentication, not Governance publishing permission.
# Keep mutations closed until the authoritative permission and author identity are available.
class PublishingEntryPolicy < ApplicationPolicy
  public

  def index? = staff_operator_in_force?

  def show? = staff_operator_in_force?

  def create? = staff_operator_in_force?

  def update? = staff_operator_in_force?

  def destroy? = staff_operator_in_force?

  private

  def staff_operator_in_force?
    return false unless user.is_a?(RpEditOrgPrincipal)
    return false if user.deactivated?

    raise GovernanceUnavailableError, "Publishing authorization and author identity require Governance"
  end
end
