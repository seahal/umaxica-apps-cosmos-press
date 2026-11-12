# frozen_string_literal: true

require "test_helper"

module Publishing
  class MediaDimensionsContractTest < ActiveSupport::TestCase
    self.fixture_table_names = []

    test "media dimensions accept unknown or paired positive PostgreSQL integers" do
      [[nil, nil], [1, 1], [2, 2], [2_147_483_646, 1],
       [2_147_483_647, 2_147_483_647],].each_with_index do |(width, height), index|
        media = MediaFile.create!(
          storage_key: "dimensions/valid-#{index}", content_type: "image/png", byte_size: 1,
          digest_algorithm: "sha256", digest: "d" * 64, width: width, height: height,
        )

        assert_equal [width, height], media.reload.attributes.values_at("width", "height")
        media.update!(width: nil, height: nil)

        assert_nil media.reload.width
        assert_nil media.height
        media.update!(width: 1, height: 1)

        assert_equal [1, 1], media.reload.attributes.values_at("width", "height")
      end
    end

    test "media dimensions reject unpaired nonpositive and out of range model values" do
      [[nil, 1], [1, nil], [-1, 1], [1, -1], [0, 1], [1, 0],
       [2_147_483_648, 1], [1, 2_147_483_648],].each do |width, height|
        media = MediaFile.new(
          storage_key: "dimensions/invalid", content_type: "image/png", byte_size: 1,
          digest_algorithm: "sha256", digest: "d" * 64, width: width, height: height,
        )

        assert_not media.valid?, "dimensions #{[width, height].inspect} must be rejected"
        assert(media.errors[:width].any? || media.errors[:height].any?)
        assert_raises(ActiveRecord::RecordInvalid) { media.save! }
        assert_predicate media, :new_record?
      end
    end

    test "insert_all cannot bypass paired positive dimensions" do
      [[nil, 1], [1, nil], [-1, 1], [1, -1], [0, 1], [1, 0]].each_with_index do |(width, height), index|
        error =
          assert_raises(ActiveRecord::StatementInvalid) do
            MediaFile.transaction(requires_new: true) do
              MediaFile.insert_all!(
                [
                  { public_id: format("D%020d", index),
                    storage_key: "dimensions/insert-#{index}",
                    content_type: "image/png",
                    byte_size: 1,
                    digest_algorithm: "sha256",
                    digest: "d" * 64,
                    width: width,
                    height: height, },
                ],
              )
            end
          end
        assert_instance_of PG::CheckViolation, error.cause
        assert_equal "chk_publishing_media_dimensions",
                     error.cause.result.error_field(PG::Result::PG_DIAG_CONSTRAINT_NAME)
        assert_not MediaFile.exists?(storage_key: "dimensions/insert-#{index}")
      end
    end

    test "update_all cannot bypass paired positive dimensions or change the original row" do
      media = MediaFile.create!(
        storage_key: "dimensions/update", content_type: "image/png", byte_size: 1,
        digest_algorithm: "sha256", digest: "d" * 64, width: 1, height: 1,
      )

      [[nil, 1], [1, nil], [-1, 1], [1, -1], [0, 1], [1, 0]].each do |width, height|
        error =
          assert_raises(ActiveRecord::StatementInvalid) do
            MediaFile.transaction(requires_new: true) do
              MediaFile.where(id: media.id).update_all(width: width, height: height)
            end
          end
        assert_instance_of PG::CheckViolation, error.cause
        assert_equal "chk_publishing_media_dimensions",
                     error.cause.result.error_field(PG::Result::PG_DIAG_CONSTRAINT_NAME)
        assert_equal [1, 1], media.reload.attributes.values_at("width", "height")
      end
    end
  end
end
