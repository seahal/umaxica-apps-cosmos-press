# typed: false
# frozen_string_literal: true

# Base policy class for authorization using Action Policy
class ApplicationPolicy < ActionPolicy::Base
  authorize :user, optional: true
  authorize :access_token_claims, optional: true

  alias_rule :edit?, to: :update?
  alias_rule :new?, to: :create?

  # Session capability layer. Authorization is DB role AND session capability
  # AND the ordinary policy rule; an authentication context can only ever
  # narrow what the actor's roles already allow, never widen it. Normal and
  # Standby contexts pass it; an unrecognised context fails every rule.
  # Standby sessions are kept from sensitive actions by Step-Up gates, not
  # here (docs/security/org-emergency-access.md).
  pre_check :deny_capability_restricted_context

  public

  def edit? = update?

  def new? = create?

  # Default permissions - deny all by default (allowlist approach)
  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def update?
    false
  end

  def destroy?
    false
  end

  relation_scope do |relation|
    relation.none
  end

  private

  # Named by the pre_check above; Action Policy resolves it on the policy
  # instance, so it is not part of the policy's public rule vocabulary.
  def deny_capability_restricted_context
    rule = result&.rule
    return if rule.blank?

    deny! if user.blank?
    deny! unless authentication_context.permits_rule?(rule)
  end

  # The caller supplies claims only after verifying its own request credential. Missing or
  # malformed context grants nothing; a verified legacy payload without the claim keeps Normal
  # semantics, while an unrecognised claim has no capabilities.
  def authentication_context
    return AuthenticationContextValue::UNKNOWN unless access_token_claims.is_a?(Hash)

    AuthorizationTokenClaims.authentication_context(access_token_claims)
  end
end
