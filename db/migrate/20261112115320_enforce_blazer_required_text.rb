# frozen_string_literal: true

class EnforceBlazerRequiredText < ActiveRecord::Migration[8.2]
  COLUMNS = [
    [:blazer_queries, :statement, "chk_blazer_queries_statement_present"],
    [:blazer_dashboards, :name, "chk_blazer_dashboards_name_present"],
  ].freeze

  # Match Active Support's Unicode White_Space presence semantics independently of database locale.
  NONBLANK_PATTERN = <<~'SQL'.squish
    U&'[^\0009-\000D\0020\0085\00A0\1680\2000-\200A\2028\2029\202F\205F\3000]'
  SQL

  def up
    COLUMNS.each do |table, column, name|
      expression = "#{quote_column_name(column)} ~ #{NONBLANK_PATTERN}"
      count = select_value("SELECT count(*) FROM #{quote_table_name(table)} WHERE NOT (#{expression})").to_i
      if count.positive?
        raise ActiveRecord::MigrationError, "#{table}.#{column} has #{count} blank values; repair before retrying"
      end

      # Validation scans existing rows under a lock; production needs a table-size review.
      safety_assured { add_check_constraint(table, expression, name: name) }
    end
  end

  def down
    COLUMNS.reverse_each { |table, _column, name| remove_check_constraint(table, name: name) }
  end
end
