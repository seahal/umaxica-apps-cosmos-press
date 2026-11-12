# frozen_string_literal: true

class GeneratePublishingTaxonomyPositions < ActiveRecord::Migration[8.2]
  TABLES = [
    [:publishing_docs_app_version_multiple_taxonomy_assignments, "chk_docs_app_vm_pos"],
    [:publishing_docs_com_version_multiple_taxonomy_assignments, "chk_docs_com_vm_pos"],
    [:publishing_docs_org_version_multiple_taxonomy_assignments, "chk_docs_org_vm_pos"],
    [:publishing_help_app_version_multiple_taxonomy_assignments, "chk_help_app_vm_pos"],
    [:publishing_help_com_version_multiple_taxonomy_assignments, "chk_help_com_vm_pos"],
    [:publishing_help_org_version_multiple_taxonomy_assignments, "chk_help_org_vm_pos"],
    [:publishing_info_app_version_multiple_taxonomy_assignments, "chk_info_app_vm_pos"],
    [:publishing_info_com_version_multiple_taxonomy_assignments, "chk_info_com_vm_pos"],
    [:publishing_info_org_version_multiple_taxonomy_assignments, "chk_info_org_vm_pos"],
    [:publishing_news_app_version_multiple_taxonomy_assignments, "chk_news_app_vm_pos"],
    [:publishing_news_com_version_multiple_taxonomy_assignments, "chk_news_com_vm_pos"],
    [:publishing_news_org_version_multiple_taxonomy_assignments, "chk_news_org_vm_pos"],
  ].freeze

  ORIGINAL_SNAPSHOT_FUNCTION = <<~SQL.squish
    CREATE OR REPLACE FUNCTION publishing_version_assignment_snapshot() RETURNS trigger AS $$
    DECLARE
      vocab_table text := TG_ARGV[0];
      terms_table text := TG_ARGV[1];
      ordered boolean := TG_ARGV[2] = 'ordered';
      vocabulary_public_id text;
      vocabulary_key text;
      vocabulary_kind text;
      term_public_id text;
      term_slug text;
      term_name text;
      term_locale text;
    BEGIN
      EXECUTE format('SELECT public_id, key, kind FROM public.%I WHERE id = $1', vocab_table)
        INTO vocabulary_public_id, vocabulary_key, vocabulary_kind USING NEW.vocabulary_id;
      EXECUTE format('SELECT public_id, slug, name, locale FROM public.%I WHERE id = $1', terms_table)
        INTO term_public_id, term_slug, term_name, term_locale USING NEW.taxonomy_term_id;
      IF vocabulary_public_id IS NULL OR term_public_id IS NULL THEN
        RAISE EXCEPTION 'publishing taxonomy: cannot snapshot a missing vocabulary or term'
          USING ERRCODE = 'foreign_key_violation';
      END IF;
      NEW.vocabulary_public_id_snapshot := vocabulary_public_id;
      NEW.vocabulary_key_snapshot := vocabulary_key;
      NEW.vocabulary_kind_snapshot := vocabulary_kind;
      NEW.term_public_id_snapshot := term_public_id;
      NEW.term_slug_snapshot := term_slug;
      NEW.term_name_snapshot := term_name;
      NEW.term_path_snapshot := publishing_taxonomy_term_path(terms_table, NEW.taxonomy_term_id);
      NEW.locale_snapshot := term_locale;
      IF ordered THEN
        NEW.position_snapshot := NEW.position;
      END IF;
      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql SET search_path = pg_catalog, public;
  SQL

  GENERATED_SNAPSHOT_FUNCTION = <<~SQL.squish
    CREATE OR REPLACE FUNCTION publishing_version_assignment_snapshot() RETURNS trigger AS $$
    DECLARE
      vocab_table text := TG_ARGV[0];
      terms_table text := TG_ARGV[1];
      vocabulary_public_id text;
      vocabulary_key text;
      vocabulary_kind text;
      term_public_id text;
      term_slug text;
      term_name text;
      term_locale text;
    BEGIN
      EXECUTE format('SELECT public_id, key, kind FROM public.%I WHERE id = $1', vocab_table)
        INTO vocabulary_public_id, vocabulary_key, vocabulary_kind USING NEW.vocabulary_id;
      EXECUTE format('SELECT public_id, slug, name, locale FROM public.%I WHERE id = $1', terms_table)
        INTO term_public_id, term_slug, term_name, term_locale USING NEW.taxonomy_term_id;
      IF vocabulary_public_id IS NULL OR term_public_id IS NULL THEN
        RAISE EXCEPTION 'publishing taxonomy: cannot snapshot a missing vocabulary or term'
          USING ERRCODE = 'foreign_key_violation';
      END IF;
      NEW.vocabulary_public_id_snapshot := vocabulary_public_id;
      NEW.vocabulary_key_snapshot := vocabulary_key;
      NEW.vocabulary_kind_snapshot := vocabulary_kind;
      NEW.term_public_id_snapshot := term_public_id;
      NEW.term_slug_snapshot := term_slug;
      NEW.term_name_snapshot := term_name;
      NEW.term_path_snapshot := publishing_taxonomy_term_path(terms_table, NEW.taxonomy_term_id);
      NEW.locale_snapshot := term_locale;
      RETURN NEW;
    END;
    $$ LANGUAGE plpgsql SET search_path = pg_catalog, public;
  SQL

  def up
    TABLES.each do |table, _constraint|
      count = select_value(<<~SQL.squish).to_i
        SELECT count(*) FROM #{quote_table_name(table)}
        WHERE position_snapshot IS DISTINCT FROM position
      SQL
      next if count.zero?

      raise ActiveRecord::MigrationError,
            "#{table} has #{count} inconsistent position snapshots; investigate historical data before retrying"
    end

    # Replacing a stored column rewrites each table under ACCESS EXCLUSIVE locks. The transaction
    # preserves the original columns and trigger on failure; review sizes and pause writers first.
    safety_assured do
      execute(GENERATED_SNAPSHOT_FUNCTION)
      TABLES.each do |table, constraint|
        remove_check_constraint(table, name: constraint)
        remove_column(table, :position_snapshot)
        add_column(table, :position_snapshot, :virtual, type: :integer, as: "position", stored: true, null: false)
        add_check_constraint(table, "position >= 0 AND position_snapshot >= 0", name: constraint)
      end
    end
  end

  def down
    safety_assured do
      TABLES.reverse_each do |table, _constraint|
        # PostgreSQL retains the computed stored values, NOT NULL and CHECK when dropping generation.
        # Active Record has no migration DSL for DROP EXPRESSION; no historical row is updated.
        execute("ALTER TABLE #{quote_table_name(table)} ALTER COLUMN position_snapshot DROP EXPRESSION")
      end
      execute(ORIGINAL_SNAPSHOT_FUNCTION)
    end
  end
end
