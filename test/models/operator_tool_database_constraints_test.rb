# frozen_string_literal: true

require "test_helper"

# Blazer is loaded only in development; its persisted contracts still protect direct SQL in every environment.
class OperatorToolDatabaseConstraintsTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  test "operator queries dashboards and links persist with optional creator and query name" do
    connection = ApplicationRecord.lease_connection
    query_id = connection.select_value(<<~SQL.squish)
      INSERT INTO blazer_queries (statement, created_at, updated_at)
      VALUES ('SELECT 1', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP) RETURNING id
    SQL
    dashboard_id = connection.select_value(<<~SQL.squish)
      INSERT INTO blazer_dashboards (name, created_at, updated_at)
      VALUES ('Database contract', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP) RETURNING id
    SQL
    connection.execute(<<~SQL.squish)
      INSERT INTO blazer_checks (query_id, created_at, updated_at)
      VALUES (#{connection.quote(query_id)}, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
    SQL
    connection.execute(<<~SQL.squish)
      INSERT INTO blazer_dashboard_queries (dashboard_id, query_id, created_at, updated_at)
      VALUES (#{connection.quote(dashboard_id)}, #{connection.quote(query_id)}, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
    SQL

    assert_equal(
      1, connection.select_value("SELECT count(*) FROM blazer_checks WHERE query_id = #{connection.quote(query_id)}"),
    )
    assert_nil connection.select_value("SELECT name FROM blazer_queries WHERE id = #{connection.quote(query_id)}")
    assert_nil(
      connection.select_value("SELECT creator_id FROM blazer_dashboards WHERE id = #{connection.quote(dashboard_id)}"),
    )
  end

  test "operator persistence rejects missing required fields without model validations" do
    connection = ApplicationRecord.lease_connection
    statements = [
      "INSERT INTO blazer_queries (created_at, updated_at) VALUES (CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
      "INSERT INTO blazer_dashboards (created_at, updated_at) VALUES (CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
      "INSERT INTO blazer_checks (created_at, updated_at) VALUES (CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
      "INSERT INTO blazer_dashboard_queries (query_id, created_at, updated_at) " \
      "VALUES (1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
      "INSERT INTO blazer_dashboard_queries (dashboard_id, created_at, updated_at) " \
      "VALUES (1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
    ]
    statements.each do |statement|
      error =
        assert_raises(ActiveRecord::NotNullViolation) do
          ApplicationRecord.transaction(requires_new: true) { connection.execute(statement) }
        end
      assert_instance_of PG::NotNullViolation, error.cause
    end
  end

  test "operator persistence rejects nonexistent association targets" do
    connection = ApplicationRecord.lease_connection
    query_id = connection.select_value(<<~SQL.squish)
      INSERT INTO blazer_queries (statement, created_at, updated_at)
      VALUES ('SELECT 1', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP) RETURNING id
    SQL
    dashboard_id = connection.select_value(<<~SQL.squish)
      INSERT INTO blazer_dashboards (name, created_at, updated_at)
      VALUES ('Database contract', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP) RETURNING id
    SQL
    statements = [
      "INSERT INTO blazer_checks (query_id, created_at, updated_at) " \
      "VALUES (9223372036854775807, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
      "INSERT INTO blazer_dashboard_queries (dashboard_id, query_id, created_at, updated_at) " \
      "VALUES (9223372036854775807, #{connection.quote(query_id)}, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
      "INSERT INTO blazer_dashboard_queries (dashboard_id, query_id, created_at, updated_at) " \
      "VALUES (#{connection.quote(dashboard_id)}, 9223372036854775807, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)",
    ]
    statements.each do |statement|
      error =
        assert_raises(ActiveRecord::InvalidForeignKey) do
          ApplicationRecord.transaction(requires_new: true) { connection.execute(statement) }
        end
      assert_instance_of PG::ForeignKeyViolation, error.cause
    end
  end

  test "required operator text rejects the same Unicode whitespace partitions as presence validation" do
    connection = ApplicationRecord.lease_connection
    [["blazer_queries", "statement"], ["blazer_dashboards", "name"]].each do |table, column|
      ["", " ", "\t\n\r", "\u0085", "\u00A0", "\u1680", "\u2007", "\u2028", "\u202F", "\u205F",
       "\u3000",].each do |value|
        assert_predicate value, :blank?
        error =
          assert_raises(ActiveRecord::StatementInvalid) do
            ApplicationRecord.transaction(requires_new: true) do
              statement = <<~SQL.squish
                INSERT INTO #{table} (#{column}, created_at, updated_at)
                VALUES ($1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
              SQL
              bind = ActiveRecord::Relation::QueryAttribute.new(column, value, ActiveRecord::Type::String.new)
              connection.exec_query(statement, "SQL", [bind])
            end
          end
        assert_instance_of PG::CheckViolation, error.cause
      end
      ["value", "0", "\u3000value\u3000", "\u200B"].each do |value|
        assert_not_predicate value, :blank?
        statement = <<~SQL.squish
          INSERT INTO #{table} (#{column}, created_at, updated_at)
          VALUES ($1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP) RETURNING id
        SQL
        bind = ActiveRecord::Relation::QueryAttribute.new(column, value, ActiveRecord::Type::String.new)
        id = connection.exec_query(statement, "SQL", [bind]).rows.first.first

        assert_equal value, connection.select_value("SELECT #{column} FROM #{table} WHERE id = #{connection.quote(id)}")
      end
    end
  end

  test "operator parent deletion requires child first cleanup rather than cascading" do
    connection = ApplicationRecord.lease_connection
    query_id = connection.select_value(<<~SQL.squish)
      INSERT INTO blazer_queries (statement, created_at, updated_at)
      VALUES ('SELECT 1', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP) RETURNING id
    SQL
    dashboard_id = connection.select_value(<<~SQL.squish)
      INSERT INTO blazer_dashboards (name, created_at, updated_at)
      VALUES ('Database contract', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP) RETURNING id
    SQL
    connection.execute(<<~SQL.squish)
      INSERT INTO blazer_checks (query_id, created_at, updated_at)
      VALUES (#{connection.quote(query_id)}, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
    SQL
    connection.execute(<<~SQL.squish)
      INSERT INTO blazer_dashboard_queries (dashboard_id, query_id, created_at, updated_at)
      VALUES (#{connection.quote(dashboard_id)}, #{connection.quote(query_id)}, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
    SQL
    [["blazer_queries", query_id], ["blazer_dashboards", dashboard_id]].each do |table, id|
      assert_raises(ActiveRecord::InvalidForeignKey) do
        ApplicationRecord.transaction(requires_new: true) do
          connection.execute("DELETE FROM #{table} WHERE id = #{connection.quote(id)}")
        end
      end
    end
    connection.execute("DELETE FROM blazer_checks WHERE query_id = #{connection.quote(query_id)}")
    connection.execute("DELETE FROM blazer_dashboard_queries WHERE query_id = #{connection.quote(query_id)}")
    connection.execute("DELETE FROM blazer_queries WHERE id = #{connection.quote(query_id)}")
    connection.execute("DELETE FROM blazer_dashboards WHERE id = #{connection.quote(dashboard_id)}")

    remaining_queries = connection.select_value(
      "SELECT count(*) FROM blazer_queries WHERE id = #{connection.quote(query_id)}",
    )
    remaining_dashboards = connection.select_value(
      "SELECT count(*) FROM blazer_dashboards WHERE id = #{connection.quote(dashboard_id)}",
    )

    assert_equal 0, remaining_queries
    assert_equal 0, remaining_dashboards
  end
end
