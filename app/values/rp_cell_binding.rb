# typed: false
# frozen_string_literal: true

# Fixed process-to-cell bindings for R5. A request may carry a client identifier, but it never
# selects the database connection; callers resolve this value from trusted boot configuration.
class RpCellBinding
  Cell = Data.define(:connection, :client_id, :realm, :region, :record_prefix)

  CELLS = {
    "rp_edit_org" => Cell.new(
      connection: "rp_edit_org", client_id: "edit-org-ww", realm: "org", region: "ww",
      record_prefix: "RpEditOrg",
    ),
  }.freeze

  class UnknownCell < KeyError; end

  class << self
    public

    def fetch(connection)
      CELLS.fetch(connection.to_s) { raise UnknownCell, "unknown RP cell connection: #{connection.inspect}" }
    end

    def for_client(client_id)
      cell = CELLS.values.find { |candidate| candidate.client_id == client_id.to_s }
      return cell if cell

      raise UnknownCell, "unknown RP client binding: #{client_id.inspect}"
    end

    def connections
      CELLS.keys
    end
  end
end
