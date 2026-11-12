# frozen_string_literal: true

module Publishing
  class MediaFile < PublishingRecord
    self.table_name = "publishing_media_files"

    include PublicId
    include PublishingMediaUploader::Attachment[:file]

    has_many :docs_app_revision_media_usages, class_name: "Publishing::Docs::App::RevisionMediaUsage",
                                              inverse_of: :media_file, dependent: :restrict_with_exception
    has_many :docs_app_version_media_usages, class_name: "Publishing::Docs::App::VersionMediaUsage",
                                             inverse_of: :media_file, dependent: :restrict_with_exception
    has_many :docs_com_revision_media_usages, class_name: "Publishing::Docs::Com::RevisionMediaUsage",
                                              inverse_of: :media_file, dependent: :restrict_with_exception
    has_many :docs_com_version_media_usages, class_name: "Publishing::Docs::Com::VersionMediaUsage",
                                             inverse_of: :media_file, dependent: :restrict_with_exception
    has_many :docs_org_revision_media_usages, class_name: "Publishing::Docs::Org::RevisionMediaUsage",
                                              inverse_of: :media_file, dependent: :restrict_with_exception
    has_many :docs_org_version_media_usages, class_name: "Publishing::Docs::Org::VersionMediaUsage",
                                             inverse_of: :media_file, dependent: :restrict_with_exception
    has_many :help_app_revision_media_usages, class_name: "Publishing::Help::App::RevisionMediaUsage",
                                              inverse_of: :media_file, dependent: :restrict_with_exception
    has_many :help_app_version_media_usages, class_name: "Publishing::Help::App::VersionMediaUsage",
                                             inverse_of: :media_file, dependent: :restrict_with_exception
    has_many :help_com_revision_media_usages, class_name: "Publishing::Help::Com::RevisionMediaUsage",
                                              inverse_of: :media_file, dependent: :restrict_with_exception
    has_many :help_com_version_media_usages, class_name: "Publishing::Help::Com::VersionMediaUsage",
                                             inverse_of: :media_file, dependent: :restrict_with_exception
    has_many :help_org_revision_media_usages, class_name: "Publishing::Help::Org::RevisionMediaUsage",
                                              inverse_of: :media_file, dependent: :restrict_with_exception
    has_many :help_org_version_media_usages, class_name: "Publishing::Help::Org::VersionMediaUsage",
                                             inverse_of: :media_file, dependent: :restrict_with_exception
    has_many :info_app_revision_media_usages, class_name: "Publishing::Info::App::RevisionMediaUsage",
                                              inverse_of: :media_file, dependent: :restrict_with_exception
    has_many :info_app_version_media_usages, class_name: "Publishing::Info::App::VersionMediaUsage",
                                             inverse_of: :media_file, dependent: :restrict_with_exception
    has_many :info_com_revision_media_usages, class_name: "Publishing::Info::Com::RevisionMediaUsage",
                                              inverse_of: :media_file, dependent: :restrict_with_exception
    has_many :info_com_version_media_usages, class_name: "Publishing::Info::Com::VersionMediaUsage",
                                             inverse_of: :media_file, dependent: :restrict_with_exception
    has_many :info_org_revision_media_usages, class_name: "Publishing::Info::Org::RevisionMediaUsage",
                                              inverse_of: :media_file, dependent: :restrict_with_exception
    has_many :info_org_version_media_usages, class_name: "Publishing::Info::Org::VersionMediaUsage",
                                             inverse_of: :media_file, dependent: :restrict_with_exception
    has_many :news_app_revision_media_usages, class_name: "Publishing::News::App::RevisionMediaUsage",
                                              inverse_of: :media_file, dependent: :restrict_with_exception
    has_many :news_app_version_media_usages, class_name: "Publishing::News::App::VersionMediaUsage",
                                             inverse_of: :media_file, dependent: :restrict_with_exception
    has_many :news_com_revision_media_usages, class_name: "Publishing::News::Com::RevisionMediaUsage",
                                              inverse_of: :media_file, dependent: :restrict_with_exception
    has_many :news_com_version_media_usages, class_name: "Publishing::News::Com::VersionMediaUsage",
                                             inverse_of: :media_file, dependent: :restrict_with_exception
    has_many :news_org_revision_media_usages, class_name: "Publishing::News::Org::RevisionMediaUsage",
                                              inverse_of: :media_file, dependent: :restrict_with_exception
    has_many :news_org_version_media_usages, class_name: "Publishing::News::Org::VersionMediaUsage",
                                             inverse_of: :media_file, dependent: :restrict_with_exception

    validates :storage_key, uniqueness: true, on: :create
    validates :byte_size, :content_type, :digest, :digest_algorithm, :storage_key, exclusion: { in: [nil] }
    validates :width, :height,
              numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 2_147_483_647 },
              allow_nil: true
    validate :dimensions_must_be_paired

    before_validation :assign_shrine_file_metadata, if: -> { file.present? }
    after_save :sync_store_key_after_promote, if: -> { file.present? }

    private

    def dimensions_must_be_paired
      errors.add(:width, :blank) if width.nil? && !height.nil?
      errors.add(:height, :blank) if height.nil? && !width.nil?
    end

    def shrine_file_column_values
      {
        storage_key: file.id,
        content_type: file.mime_type,
        byte_size: file.size,
        digest_algorithm: "sha256",
        digest: file.metadata["sha256"],
      }
    end

    def assign_shrine_file_metadata
      assign_attributes(shrine_file_column_values)
    end

    def sync_store_key_after_promote
      values = shrine_file_column_values
      return if storage_key == values.fetch(:storage_key)

      update(values)
    end
  end
end
