# typed: false
# frozen_string_literal: true

require "test_helper"

# Small comparisons and derivations that decide whether a session is spared, an
# address is real, a proof is trusted, or a host belongs to a brand edition. Each
# has one arm that answers conservatively, and each conservative answer is the
# safe one: revoke rather than spare, refuse rather than trust, raise rather than
# guess.
class SessionIdentityHelperRefusalsTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  # A stored public key that is not usable JWK material is server-side state, not
  # a client-supplied proof, and is reported separately so operations does not
  # read data corruption as a hijack attempt.
  test "a host with no brand edition among its labels is refused rather than guessed at" do
    helper = Object.new.extend(ApplicationHelper)
    helper.define_singleton_method(:request) { Struct.new(:host).new("example.test") }

    error = assert_raises(ArgumentError) { helper.brand_tld }

    assert_match(/Cannot derive a brand TLD/, error.message)
  end

  test "a host carrying a brand edition reports it in upper case" do
    { "docs.app.localhost" => "APP", "info.com.localhost" => "COM", "edit.org.localhost" => "ORG" }
      .each do |host, expected|
        helper = Object.new.extend(ApplicationHelper)
        helper.define_singleton_method(:request) { Struct.new(:host).new(host) }

        assert_equal expected, helper.brand_tld, host
      end
  end
end
