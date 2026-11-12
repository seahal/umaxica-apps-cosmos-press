# frozen_string_literal: true

class EnforcePublishingMediaPlacementUniqueness < ActiveRecord::Migration[8.2]
  INDEXES = [
    [:publishing_docs_app_revision_media_usages, :entry_revision_id, "uidx_docs_app_rev_media_pos"],
    [:publishing_docs_app_version_media_usages, :entry_version_id, "uidx_docs_app_ver_media_pos"],
    [:publishing_docs_com_revision_media_usages, :entry_revision_id, "uidx_docs_com_rev_media_pos"],
    [:publishing_docs_com_version_media_usages, :entry_version_id, "uidx_docs_com_ver_media_pos"],
    [:publishing_docs_org_revision_media_usages, :entry_revision_id, "uidx_docs_org_rev_media_pos"],
    [:publishing_docs_org_version_media_usages, :entry_version_id, "uidx_docs_org_ver_media_pos"],
    [:publishing_help_app_revision_media_usages, :entry_revision_id, "uidx_help_app_rev_media_pos"],
    [:publishing_help_app_version_media_usages, :entry_version_id, "uidx_help_app_ver_media_pos"],
    [:publishing_help_com_revision_media_usages, :entry_revision_id, "uidx_help_com_rev_media_pos"],
    [:publishing_help_com_version_media_usages, :entry_version_id, "uidx_help_com_ver_media_pos"],
    [:publishing_help_org_revision_media_usages, :entry_revision_id, "uidx_help_org_rev_media_pos"],
    [:publishing_help_org_version_media_usages, :entry_version_id, "uidx_help_org_ver_media_pos"],
    [:publishing_info_app_revision_media_usages, :entry_revision_id, "uidx_info_app_rev_media_pos"],
    [:publishing_info_app_version_media_usages, :entry_version_id, "uidx_info_app_ver_media_pos"],
    [:publishing_info_com_revision_media_usages, :entry_revision_id, "uidx_info_com_rev_media_pos"],
    [:publishing_info_com_version_media_usages, :entry_version_id, "uidx_info_com_ver_media_pos"],
    [:publishing_info_org_revision_media_usages, :entry_revision_id, "uidx_info_org_rev_media_pos"],
    [:publishing_info_org_version_media_usages, :entry_version_id, "uidx_info_org_ver_media_pos"],
    [:publishing_news_app_revision_media_usages, :entry_revision_id, "uidx_news_app_rev_media_pos"],
    [:publishing_news_app_version_media_usages, :entry_version_id, "uidx_news_app_ver_media_pos"],
    [:publishing_news_com_revision_media_usages, :entry_revision_id, "uidx_news_com_rev_media_pos"],
    [:publishing_news_com_version_media_usages, :entry_version_id, "uidx_news_com_ver_media_pos"],
    [:publishing_news_org_revision_media_usages, :entry_revision_id, "uidx_news_org_rev_media_pos"],
    [:publishing_news_org_version_media_usages, :entry_version_id, "uidx_news_org_ver_media_pos"],
  ].freeze

  def up
    # Atomic replacement keeps the old constraint until its stronger replacement exists.
    # Index builds lock writes; production requires a table-size and maintenance-window review.
    safety_assured do
      INDEXES.each do |table, owner, name|
        # Build first: existing duplicates abort the transaction without removing protection or data.
        add_index(
          table, [owner, :role, :field_path, :block_path, :position],
          unique: true, nulls_not_distinct: true, name: "#{name}_nnd",
        )
        remove_index(table, name: name)
        rename_index(table, "#{name}_nnd", name)
      end
    end
  end

  def down
    safety_assured do
      INDEXES.reverse_each do |table, owner, name|
        add_index(
          table, [owner, :role, :field_path, :block_path, :position],
          unique: true, name: "#{name}_old",
        )
        remove_index(table, name: name)
        rename_index(table, "#{name}_old", name)
      end
    end
  end
end
