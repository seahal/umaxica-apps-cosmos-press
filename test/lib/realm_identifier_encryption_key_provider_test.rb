# typed: false
# frozen_string_literal: true

require "test_helper"

class RealmIdentifierEncryptionKeyProviderTest < ActiveSupport::TestCase
  test "builds a key provider from the selected realm's configured keys" do
    environment = {
      "APP_ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY" => "current-app-key",
      "APP_ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY_PREVIOUS" => '["previous-app-key"]',
      "APP_ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT" => "app-salt",
    }

    ENV.stub(:fetch, ->(name) { environment.fetch(name) }) do
      ENV.stub(:[], ->(name) { environment[name] }) do
        provider = RealmIdentifierEncryptionKeyProvider.key_provider(realm: "app")

        assert_instance_of ActiveRecord::Encryption::KeyProvider, provider
      end
    end
  end

  test "rejects a previous key value that is not an array of nonempty strings" do
    environment = {
      "APP_ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY" => "current-app-key",
      "APP_ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY_PREVIOUS" => '"previous-app-key"',
      "APP_ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT" => "app-salt",
    }

    ENV.stub(:fetch, ->(name) { environment.fetch(name) }) do
      ENV.stub(:[], ->(name) { environment[name] }) do
        error =
          assert_raises(ArgumentError) do
            RealmIdentifierEncryptionKeyProvider.key_provider(realm: "app")
          end

        assert_match(/previous encryption keys must be an array/, error.message)
      end
    end
  end
end
