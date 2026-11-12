# typed: false
# frozen_string_literal: true

require "test_helper"
# require "helpers/global_test_support"

class ApplicationPolicyTest < ActiveSupport::TestCase
  class TestRecord
    attr_reader :marker

    def initialize
      @marker = :test_record
    end
  end

  class RelationDouble
    attr_reader :none_called

    def none
      @none_called = true
      :none_scope
    end
  end

  class TestPolicy < ApplicationPolicy; end

  def setup
    @user = RpEditOrgPrincipal.new(id: 381)
    @claims = { "authn_ctx" => "normal" }
    @record = TestRecord.new
    @policy = TestPolicy.new(@record, user: @user, access_token_claims: @claims)
  end

  # Default behavior tests
  def test_index_returns_false_by_default
    assert_not @policy.apply(:index?)
  end

  def test_show_returns_false_by_default
    assert_not @policy.apply(:show?)
  end

  def test_create_returns_false_by_default
    assert_not @policy.apply(:create?)
  end

  def test_new_delegates_to_create
    assert_equal @policy.apply(:create?), @policy.apply(:new?)
  end

  def test_update_returns_false_by_default
    assert_not @policy.apply(:update?)
  end

  def test_edit_delegates_to_update
    assert_equal @policy.apply(:update?), @policy.apply(:edit?)
  end

  def test_destroy_returns_false_by_default
    assert_not @policy.apply(:destroy?)
  end

  def test_relation_scope_denies_all_by_default
    relation = RelationDouble.new

    assert_equal :none_scope, @policy.apply_scope(relation, type: :active_record_relation)
    assert relation.none_called
  end

  # Attributes tests
  def test_explicit_nil_user_attribute_is_accessible_but_has_no_domain_authority
    policy = ApplicationPolicy.new(@record, user: nil, access_token_claims: @claims)

    assert_nil policy.user
  end

  def test_record_attribute_is_accessible
    policy = ApplicationPolicy.new(@record, user: @user, access_token_claims: @claims)

    assert_equal @record, policy.record
  end

  private
end
