# frozen_string_literal: true

# Retained restoration references are queried by the owning revision/version and
# checked when a source is deleted. Concurrent builds avoid blocking writers.
class IndexPublishingRestorationReferences < ActiveRecord::Migration[8.2]
  disable_ddl_transaction!

  def up
    add_docs_restoration_indexes
    add_help_restoration_indexes
    add_info_restoration_indexes
    add_news_restoration_indexes
  end

  def down
    remove_news_restoration_indexes
    remove_info_restoration_indexes
    remove_help_restoration_indexes
    remove_docs_restoration_indexes
  end

  private

  def add_docs_restoration_indexes
    add_index(
      :publishing_docs_app_entry_revisions, :restored_from_revision_id,
      name: "idx_docs_app_rev_restored_revision", algorithm: :concurrently,
    )
    add_index(
      :publishing_docs_app_entry_revisions, :restored_from_version_id,
      name: "idx_docs_app_rev_restored_version", algorithm: :concurrently,
    )
    add_index(
      :publishing_docs_com_entry_revisions, :restored_from_revision_id,
      name: "idx_docs_com_rev_restored_revision", algorithm: :concurrently,
    )
    add_index(
      :publishing_docs_com_entry_revisions, :restored_from_version_id,
      name: "idx_docs_com_rev_restored_version", algorithm: :concurrently,
    )
    add_index(
      :publishing_docs_org_entry_revisions, :restored_from_revision_id,
      name: "idx_docs_org_rev_restored_revision", algorithm: :concurrently,
    )
    add_index(
      :publishing_docs_org_entry_revisions, :restored_from_version_id,
      name: "idx_docs_org_rev_restored_version", algorithm: :concurrently,
    )
  end

  def add_help_restoration_indexes
    add_index(
      :publishing_help_app_entry_revisions, :restored_from_revision_id,
      name: "idx_help_app_rev_restored_revision", algorithm: :concurrently,
    )
    add_index(
      :publishing_help_app_entry_revisions, :restored_from_version_id,
      name: "idx_help_app_rev_restored_version", algorithm: :concurrently,
    )
    add_index(
      :publishing_help_com_entry_revisions, :restored_from_revision_id,
      name: "idx_help_com_rev_restored_revision", algorithm: :concurrently,
    )
    add_index(
      :publishing_help_com_entry_revisions, :restored_from_version_id,
      name: "idx_help_com_rev_restored_version", algorithm: :concurrently,
    )
    add_index(
      :publishing_help_org_entry_revisions, :restored_from_revision_id,
      name: "idx_help_org_rev_restored_revision", algorithm: :concurrently,
    )
    add_index(
      :publishing_help_org_entry_revisions, :restored_from_version_id,
      name: "idx_help_org_rev_restored_version", algorithm: :concurrently,
    )
  end

  def add_info_restoration_indexes
    add_index(
      :publishing_info_app_entry_revisions, :restored_from_revision_id,
      name: "idx_info_app_rev_restored_revision", algorithm: :concurrently,
    )
    add_index(
      :publishing_info_app_entry_revisions, :restored_from_version_id,
      name: "idx_info_app_rev_restored_version", algorithm: :concurrently,
    )
    add_index(
      :publishing_info_com_entry_revisions, :restored_from_revision_id,
      name: "idx_info_com_rev_restored_revision", algorithm: :concurrently,
    )
    add_index(
      :publishing_info_com_entry_revisions, :restored_from_version_id,
      name: "idx_info_com_rev_restored_version", algorithm: :concurrently,
    )
    add_index(
      :publishing_info_org_entry_revisions, :restored_from_revision_id,
      name: "idx_info_org_rev_restored_revision", algorithm: :concurrently,
    )
    add_index(
      :publishing_info_org_entry_revisions, :restored_from_version_id,
      name: "idx_info_org_rev_restored_version", algorithm: :concurrently,
    )
  end

  def add_news_restoration_indexes
    add_index(
      :publishing_news_app_entry_revisions, :restored_from_revision_id,
      name: "idx_news_app_rev_restored_revision", algorithm: :concurrently,
    )
    add_index(
      :publishing_news_app_entry_revisions, :restored_from_version_id,
      name: "idx_news_app_rev_restored_version", algorithm: :concurrently,
    )
    add_index(
      :publishing_news_com_entry_revisions, :restored_from_revision_id,
      name: "idx_news_com_rev_restored_revision", algorithm: :concurrently,
    )
    add_index(
      :publishing_news_com_entry_revisions, :restored_from_version_id,
      name: "idx_news_com_rev_restored_version", algorithm: :concurrently,
    )
    add_index(
      :publishing_news_org_entry_revisions, :restored_from_revision_id,
      name: "idx_news_org_rev_restored_revision", algorithm: :concurrently,
    )
    add_index(
      :publishing_news_org_entry_revisions, :restored_from_version_id,
      name: "idx_news_org_rev_restored_version", algorithm: :concurrently,
    )
  end

  def remove_news_restoration_indexes
    remove_index(
      :publishing_news_org_entry_revisions,
      name: "idx_news_org_rev_restored_version", algorithm: :concurrently,
    )
    remove_index(
      :publishing_news_org_entry_revisions,
      name: "idx_news_org_rev_restored_revision", algorithm: :concurrently,
    )
    remove_index(
      :publishing_news_com_entry_revisions,
      name: "idx_news_com_rev_restored_version", algorithm: :concurrently,
    )
    remove_index(
      :publishing_news_com_entry_revisions,
      name: "idx_news_com_rev_restored_revision", algorithm: :concurrently,
    )
    remove_index(
      :publishing_news_app_entry_revisions,
      name: "idx_news_app_rev_restored_version", algorithm: :concurrently,
    )
    remove_index(
      :publishing_news_app_entry_revisions,
      name: "idx_news_app_rev_restored_revision", algorithm: :concurrently,
    )
  end

  def remove_info_restoration_indexes
    remove_index(
      :publishing_info_org_entry_revisions,
      name: "idx_info_org_rev_restored_version", algorithm: :concurrently,
    )
    remove_index(
      :publishing_info_org_entry_revisions,
      name: "idx_info_org_rev_restored_revision", algorithm: :concurrently,
    )
    remove_index(
      :publishing_info_com_entry_revisions,
      name: "idx_info_com_rev_restored_version", algorithm: :concurrently,
    )
    remove_index(
      :publishing_info_com_entry_revisions,
      name: "idx_info_com_rev_restored_revision", algorithm: :concurrently,
    )
    remove_index(
      :publishing_info_app_entry_revisions,
      name: "idx_info_app_rev_restored_version", algorithm: :concurrently,
    )
    remove_index(
      :publishing_info_app_entry_revisions,
      name: "idx_info_app_rev_restored_revision", algorithm: :concurrently,
    )
  end

  def remove_help_restoration_indexes
    remove_index(
      :publishing_help_org_entry_revisions,
      name: "idx_help_org_rev_restored_version", algorithm: :concurrently,
    )
    remove_index(
      :publishing_help_org_entry_revisions,
      name: "idx_help_org_rev_restored_revision", algorithm: :concurrently,
    )
    remove_index(
      :publishing_help_com_entry_revisions,
      name: "idx_help_com_rev_restored_version", algorithm: :concurrently,
    )
    remove_index(
      :publishing_help_com_entry_revisions,
      name: "idx_help_com_rev_restored_revision", algorithm: :concurrently,
    )
    remove_index(
      :publishing_help_app_entry_revisions,
      name: "idx_help_app_rev_restored_version", algorithm: :concurrently,
    )
    remove_index(
      :publishing_help_app_entry_revisions,
      name: "idx_help_app_rev_restored_revision", algorithm: :concurrently,
    )
  end

  def remove_docs_restoration_indexes
    remove_index(
      :publishing_docs_org_entry_revisions,
      name: "idx_docs_org_rev_restored_version", algorithm: :concurrently,
    )
    remove_index(
      :publishing_docs_org_entry_revisions,
      name: "idx_docs_org_rev_restored_revision", algorithm: :concurrently,
    )
    remove_index(
      :publishing_docs_com_entry_revisions,
      name: "idx_docs_com_rev_restored_version", algorithm: :concurrently,
    )
    remove_index(
      :publishing_docs_com_entry_revisions,
      name: "idx_docs_com_rev_restored_revision", algorithm: :concurrently,
    )
    remove_index(
      :publishing_docs_app_entry_revisions,
      name: "idx_docs_app_rev_restored_version", algorithm: :concurrently,
    )
    remove_index(
      :publishing_docs_app_entry_revisions,
      name: "idx_docs_app_rev_restored_revision", algorithm: :concurrently,
    )
  end
end
