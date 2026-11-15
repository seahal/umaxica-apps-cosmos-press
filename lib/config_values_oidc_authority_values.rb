# frozen_string_literal: true

module ConfigValues
  OidcAuthorityValues = Data.define(:sign, :acme, :visa)
end

ConfigValuesOidcAuthorityValues = ConfigValues::OidcAuthorityValues

class << ConfigValues::OidcAuthorityValues
  public

  def build(host_family_values)
    ConfigValues::OidcAuthorityValues.new(
      sign: {
        app: host_family_values.sign_service.to_s,
        staff: host_family_values.sign_staff.to_s,
      }.freeze,
      acme: {
        app: host_family_values.base_service.to_s,
        staff: host_family_values.base_staff.to_s,
      }.freeze,
      visa: {
        app: host_family_values.visa_service.to_s,
        staff: host_family_values.visa_staff.to_s,
      }.freeze,
    ).freeze
  end
end
