# frozen_string_literal: true

class ValidateChronicleRetainedForeignKeys < ActiveRecord::Migration[8.2]
  disable_ddl_transaction!

  FOREIGN_KEYS = [
    [:app_document_audits, :app_document_audit_events, :event_id, "fk_rails_04199ae3cc"],
    [:app_document_audits, :app_document_audit_levels, :level_id, "fk_rails_a9e9b70220"],
    [:app_timeline_audits, :app_timeline_audit_events, :event_id, "fk_rails_2babaf0d7d"],
    [:app_timeline_audits, :app_timeline_audit_levels, :level_id, "fk_rails_b95cff528f"],
    [:app_preference_chronicles, :app_preference_chronicle_events, :event_id, "fk_rails_d693b46c45"],
    [:app_preference_chronicles, :app_preference_chronicle_levels, :level_id, "fk_rails_da47dd8941"],
    [:com_preference_chronicles, :com_preference_chronicle_events, :event_id, "fk_rails_c194bd8de2"],
    [:com_preference_chronicles, :com_preference_chronicle_levels, :level_id, "fk_rails_592279f49b"],
    [:org_preference_chronicles, :org_preference_chronicle_events, :event_id, "fk_rails_3829eb3d72"],
    [:org_preference_chronicles, :org_preference_chronicle_levels, :level_id, "fk_rails_f932dbadd7"],
    [:org_document_audits, :org_document_audit_events, :event_id, "fk_rails_46d3b866ce"],
    [:org_document_audits, :org_document_audit_levels, :level_id, "fk_rails_ed52fec6a9"],
    [:org_timeline_audits, :org_timeline_audit_events, :event_id, "fk_rails_eae8a241e3"],
    [:org_timeline_audits, :org_timeline_audit_levels, :level_id, "fk_rails_1c8eb96fbb"],
    [:client_chronicles, :client_chronicle_events, :event_id, "fk_rails_829f1830de"],
    [:client_chronicles, :client_chronicle_levels, :level_id, "fk_rails_868bedb021"],
    [:operator_chronicles, :operator_chronicle_events, :event_id, "fk_rails_f0451c267b"],
    [:operator_chronicles, :operator_chronicle_levels, :level_id, "fk_rails_46a8075569"],
  ].freeze

  def up
    FOREIGN_KEYS.each do |table, target, column, name|
      validate_foreign_key(table, target, column: column, name: name)
    end
    validate_foreign_key(:chronicle_outbox_entries, :chronicles, column: :chronicle_id)
  end

  # Restore validation metadata without changing deletion rules or losing rows. Each replacement
  # is atomic so rollback never exposes a window in which an orphan can be committed.
  def down
    FOREIGN_KEYS.reverse_each do |table, target, column, name|
      connection.transaction do
        remove_foreign_key(table, name: name)
        add_foreign_key(table, target, column: column, name: name, validate: false)
      end
    end
    connection.transaction do
      remove_foreign_key(:chronicle_outbox_entries, column: :chronicle_id)
      add_foreign_key(:chronicle_outbox_entries, :chronicles, column: :chronicle_id, on_delete: :nullify, validate: false)
    end
  end
end
