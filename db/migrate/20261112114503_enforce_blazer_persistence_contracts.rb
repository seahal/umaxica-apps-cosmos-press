# frozen_string_literal: true

class EnforceBlazerPersistenceContracts < ActiveRecord::Migration[8.2]
  REQUIRED_COLUMNS = [
    [:blazer_queries, :statement],
    [:blazer_dashboards, :name],
    [:blazer_checks, :query_id],
    [:blazer_dashboard_queries, :dashboard_id],
    [:blazer_dashboard_queries, :query_id],
  ].freeze

  FOREIGN_KEYS = [
    [:blazer_checks, :blazer_queries, :query_id, "fk_blazer_checks_query"],
    [:blazer_dashboard_queries, :blazer_dashboards, :dashboard_id, "fk_blazer_dashboard_queries_dashboard"],
    [:blazer_dashboard_queries, :blazer_queries, :query_id, "fk_blazer_dashboard_queries_query"],
  ].freeze

  def up
    REQUIRED_COLUMNS.each do |table, column|
      count = select_value(<<~SQL.squish).to_i
        SELECT count(*) FROM #{quote_table_name(table)} WHERE #{quote_column_name(column)} IS NULL
      SQL
      if count.positive?
        raise ActiveRecord::MigrationError,
              "#{table}.#{column} has #{count} missing required values; repair before retrying"
      end
    end
    FOREIGN_KEYS.each do |table, target, column, _name|
      count = select_value(<<~SQL.squish).to_i
        SELECT count(*) FROM #{quote_table_name(table)}
        WHERE #{quote_column_name(column)} NOT IN (SELECT id FROM #{quote_table_name(target)})
      SQL
      if count.positive?
        raise ActiveRecord::MigrationError, "#{table}.#{column} has #{count} orphan references; repair before retrying"
      end
    end

    # Blazer already requires these values and deletes children before parents. Locking and scans
    # need a table-size and maintenance-window review before production; no data is repaired here.
    safety_assured do
      REQUIRED_COLUMNS.each { |table, column| change_column_null(table, column, false) }
      FOREIGN_KEYS.each do |table, target, column, name|
        add_foreign_key(table, target, column: column, name: name)
      end
    end
  end

  def down
    safety_assured do
      FOREIGN_KEYS.reverse_each { |table, _target, _column, name| remove_foreign_key(table, name: name) }
      REQUIRED_COLUMNS.reverse_each { |table, column| change_column_null(table, column, true) }
    end
  end
end
