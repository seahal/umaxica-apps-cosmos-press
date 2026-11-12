# typed: false
# frozen_string_literal: true

# Press owns the worldwide Edit relying party; other repositories own their client bindings.
class RpDeploymentBindingValue
  CLIENT_IDS = { "edit-org" => "edit-org-ww" }.freeze

  class UnknownRp < KeyError; end

  class << self
    public

    def client_id(family_realm)
      CLIENT_IDS.fetch(family_realm.to_s) do
        raise UnknownRp, "unknown Press RP family/realm: #{family_realm.inspect}"
      end
    end

    def active_client_ids
      CLIENT_IDS.values
    end
  end
end
