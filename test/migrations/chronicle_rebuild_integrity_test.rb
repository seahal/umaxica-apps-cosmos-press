# frozen_string_literal: true

require_relative "../../config/environment"
require "minitest/autorun"

class ChronicleRebuildIntegrityTest < Minitest::Test
  def setup
    raise ArgumentError, "isolated PostgreSQL verification requires test" unless Rails.env.test?

    original = ActiveRecord::Base.configurations.configs_for(env_name: "test", name: "chronicle")
    expected_host = Umaxica::TestEnvironment::DatabaseSafety::TEST_HOST
    raise ArgumentError, "unexpected PostgreSQL host" unless original.configuration_hash.fetch(:host) == expected_host

    database = "test_press_chronicle_integrity_#{SecureRandom.hex(6)}"
    @previous_config = ActiveRecord::Base.connection_db_config
    @config = ActiveRecord::DatabaseConfigurations::HashConfig.new(
      "test", "chronicle", original.configuration_hash.merge(database: database, replica: false),
    )
    ActiveRecord::Tasks::DatabaseTasks.create(@config)
    @created = true
    ActiveRecord::Base.establish_connection(@config)
    @pool = ActiveRecord::Base.connection_pool
    @pool.migration_context.migrate(20_261_103_183_220)
    @connection = @pool.lease_connection
  end

  def teardown
    return unless @created

    ActiveRecord::Base.connection_pool.disconnect!
    ActiveRecord::Tasks::DatabaseTasks.drop(@config)
    ActiveRecord::Base.establish_connection(@previous_config)
  end

  def test_clean_migration_history_validates_all_audit_references_and_rejects_orphans
    original_references = @connection.select_rows(<<~SQL.squish)
      SELECT conrelid::regclass::text, conname, pg_get_constraintdef(oid), convalidated
      FROM pg_constraint
      WHERE connamespace = 'public'::regnamespace AND contype = 'f'
      ORDER BY conname
    SQL
    @connection.execute(<<~SQL.squish)
      INSERT INTO chronicle_outbox_entries (event_uuid, event, status, created_at, updated_at)
      VALUES ('integrity-contract', 'audit', 'pending', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
    SQL
    @pool.migration_context.migrate

    assert_empty @connection.select_rows(<<~SQL.squish)
      SELECT conrelid::regclass::text, conname
      FROM pg_constraint
      WHERE connamespace = 'public'::regnamespace AND contype = 'f' AND NOT convalidated
      ORDER BY conname
    SQL

    assert_equal "integrity-contract", @connection.select_value("SELECT event_uuid FROM chronicle_outbox_entries")
    error =
      assert_raises(ActiveRecord::InvalidForeignKey) do
        @connection.transaction(requires_new: true) do
          @connection.execute("UPDATE chronicle_outbox_entries SET chronicle_id = 9223372036854775807")
        end
      end
    assert_instance_of PG::ForeignKeyViolation, error.cause
    assert_nil @connection.select_value("SELECT chronicle_id FROM chronicle_outbox_entries")

    @pool.migration_context.down(20_261_103_183_220)

    assert_equal original_references, @connection.select_rows(<<~SQL.squish)
      SELECT conrelid::regclass::text, conname, pg_get_constraintdef(oid), convalidated
      FROM pg_constraint
      WHERE connamespace = 'public'::regnamespace AND contype = 'f'
      ORDER BY conname
    SQL
    assert_equal "integrity-contract", @connection.select_value("SELECT event_uuid FROM chronicle_outbox_entries")
    @pool.migration_context.migrate

    assert_equal 0, @connection.select_value(<<~SQL.squish)
      SELECT count(*) FROM pg_constraint
      WHERE connamespace = 'public'::regnamespace AND contype = 'f' AND NOT convalidated
    SQL
  end
end
