# frozen_string_literal: true

require "minitest/autorun"
require "active_support/testing/assertions"
require "database_consistency"
require "active_record/connection_adapters/sql_type_metadata"
require "active_record/connection_adapters/column"

module DatabaseConsistencyLengthSubjects
  # A fixed model interface isolates the checker's proof from database I/O. Validators are real
  # Active Model validators; the column below is Rails metadata, not a fabricated checker result.
  class Record
    include ActiveModel::Model

    attr_accessor :digest, :other

    def self.primary_key = "id"

    def self.record_timestamps? = false

    def self.reflect_on_all_associations = []
  end

  class Exact < Record
    validates :digest, length: { is: 64 }
  end

  class Minimum < Record
    validates :digest, length: { minimum: 1 }
  end

  class RangeBound < Record
    validates :digest, length: { within: 1..64 }
  end

  class Creation < Record
    validates :digest, length: { is: 64 }, on: :create
  end

  class ExceptUpdate < Record
    validates :digest, length: { is: 64 }, except_on: :update
  end

  class ExplicitRefusal < Record
    validates :digest, length: { is: 64 }, allow_nil: false, allow_blank: false, on: %i(create update)
  end

  class Maximum < Record
    validates :digest, length: { maximum: 64 }
  end

  class NilAllowed < Record
    validates :digest, length: { is: 64 }, allow_nil: true
  end

  class BlankAllowed < Record
    validates :digest, length: { minimum: 1 }, allow_blank: true
  end

  class Conditional < Record
    validates :digest, length: { is: 64 }, if: -> { false }
  end

  class UnlessConditional < Record
    validates :digest, length: { is: 64 }, unless: -> { true }
  end

  class UpdateOnly < Record
    validates :digest, length: { is: 64 }, on: :update
  end

  class ExceptCreate < Record
    validates :digest, length: { is: 64 }, except_on: :create
  end

  class Dynamic < Record
    validates :digest, length: { is: -> { raise RuntimeError, "dynamic bounds must not run during inspection" } }
  end

  class SymbolBound < Record
    validates :digest, length: { is: :bound }

    def bound = raise(RuntimeError, "dynamic bounds must not run during inspection")
  end

  class PermissiveLengthValidator < ActiveModel::Validations::LengthValidator
    def validate_each(record, attribute, value)
      return if value.nil?

      super
    end
  end

  class CustomLength < Record
    validates_with PermissiveLengthValidator, attributes: [:digest], is: 64
  end

  class Zero < Record
    validates :digest, length: { is: 0 }
  end

  class ZeroMinimum < Record
    validates :digest, length: { minimum: 0 }
  end

  class Unrelated < Record
    validates :other, length: { is: 64 }
  end

  METADATA = ActiveRecord::ConnectionAdapters::SqlTypeMetadata.new(
    sql_type: "character varying(64)", type: :string, limit: 64,
  )
  COLUMN = ActiveRecord::ConnectionAdapters::Column.new("digest", ActiveRecord::Type::String.new, nil, METADATA, false)
end

class DatabaseConsistencyLengthNullabilityTest < Minitest::Test
  include ActiveSupport::Testing::Assertions

  def test_positive_constant_length_rejects_nil_but_is_not_a_checker_presence_proof
    [DatabaseConsistencyLengthSubjects::Exact, DatabaseConsistencyLengthSubjects::Minimum,
     DatabaseConsistencyLengthSubjects::RangeBound, DatabaseConsistencyLengthSubjects::Creation,
     DatabaseConsistencyLengthSubjects::ExceptUpdate,
     DatabaseConsistencyLengthSubjects::ExplicitRefusal,].each do |model|
      record = model.new(digest: nil)

      assert_not record.valid?(:create), model.name
      assert_operator record.errors.where(:digest).length, :>, 0
      report = DatabaseConsistency::Checkers::NullConstraintChecker.new(
        model, DatabaseConsistencyLengthSubjects::COLUMN,
      ).report(catch_errors: false)

      # DatabaseConsistency recognizes explicit presence validators and equivalent nil checks;
      # it does not infer presence from a length validator, even when Rails rejects nil on create.
      assert_equal :fail, report.status, model.name
    end
  end

  def test_nil_permitting_or_noncreation_validators_remain_reported
    [DatabaseConsistencyLengthSubjects::Maximum, DatabaseConsistencyLengthSubjects::NilAllowed,
     DatabaseConsistencyLengthSubjects::BlankAllowed, DatabaseConsistencyLengthSubjects::Conditional,
     DatabaseConsistencyLengthSubjects::UnlessConditional, DatabaseConsistencyLengthSubjects::UpdateOnly,
     DatabaseConsistencyLengthSubjects::ExceptCreate, DatabaseConsistencyLengthSubjects::CustomLength,].each do |model|
      assert model.new(digest: nil).valid?(:create), "#{model.name} must permit nil during creation"
      report = DatabaseConsistency::Checkers::NullConstraintChecker.new(
        model, DatabaseConsistencyLengthSubjects::COLUMN,
      ).report(catch_errors: false)

      assert_equal :fail, report.status, model.name
    end
  end

  def test_zero_and_dynamic_bounds_are_conservatively_left_for_review
    # This proof is intentionally limited to positive static bounds. Zero requires a separate
    # proof; application-provided bounds are never executed while inspecting metadata.
    [DatabaseConsistencyLengthSubjects::Zero, DatabaseConsistencyLengthSubjects::ZeroMinimum,
     DatabaseConsistencyLengthSubjects::Dynamic, DatabaseConsistencyLengthSubjects::SymbolBound,].each do |model|
      report = DatabaseConsistency::Checkers::NullConstraintChecker.new(
        model, DatabaseConsistencyLengthSubjects::COLUMN,
      ).report(catch_errors: false)

      assert_equal :fail, report.status, model.name
    end
  end

  def test_length_on_another_attribute_does_not_prove_requiredness
    report = DatabaseConsistency::Checkers::NullConstraintChecker.new(
      DatabaseConsistencyLengthSubjects::Unrelated, DatabaseConsistencyLengthSubjects::COLUMN,
    ).report(catch_errors: false)

    assert_equal :fail, report.status
  end
end
