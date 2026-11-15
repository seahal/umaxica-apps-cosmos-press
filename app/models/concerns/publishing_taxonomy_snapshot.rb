# frozen_string_literal: true

# Version assignments are frozen history. The snapshot columns -- not the live
# term rows -- are what a published version renders, so renaming, moving, or
# archiving a term never rewrites what was already published.
#
# PostgreSQL triggers reject UPDATE and DELETE on these tables. The callbacks
# here exist only to raise a readable Active Record error first.
#
# Snapshot models explicitly configure immutability after including this behavior concern.
module PublishingTaxonomySnapshot
  extend ActiveSupport::Concern

  class << self
    public

    def configure(model_class)
      model_class.class_eval do
        before_update { raise(ActiveRecord::ReadOnlyRecord, "#{self.class.name} is immutable") }
        before_destroy { raise(ActiveRecord::ReadOnlyRecord, "#{self.class.name} is immutable") }

        validates :vocabulary_public_id_snapshot, :vocabulary_key_snapshot, :vocabulary_kind_snapshot,
                  :term_public_id_snapshot, :term_slug_snapshot, :term_name_snapshot, :locale_snapshot, presence: true
        # Existing varchar(21) references reject longer input before the authoritative DB derivation.
        # Shorter supplied values remain valid and are replaced; updates retain ReadOnlyRecord refusal.
        validates :vocabulary_public_id_snapshot, :term_public_id_snapshot,
                  length: { maximum: 21 }, on: :create
      end
    end
  end
  public

  # Public rendering shape. Database identifiers never appear here.
  def as_public_json
    {
      "public_id" => term_public_id_snapshot,
      "slug" => term_slug_snapshot,
      "name" => term_name_snapshot,
    }
  end

  # Copies the live vocabulary and term into frozen columns. Called only from
  # Publishing::PromoteRevisionOperation, inside its transaction.
  def apply_snapshot(vocabulary:, term:)
    self.vocabulary_public_id_snapshot = vocabulary.public_id
    self.vocabulary_key_snapshot = vocabulary.key
    self.vocabulary_kind_snapshot = vocabulary.kind
    self.term_public_id_snapshot = term.public_id
    self.term_slug_snapshot = term.slug
    self.term_name_snapshot = term.name
    self.term_path_snapshot = term.breadcrumb
    self.locale_snapshot = term.locale
    self
  end

  private

  # Generated positions accept omission only; explicit nil and equal values are still caller input.
  def reject_user_supplied_position_snapshot
    errors.add(:position_snapshot, :invalid) if position_snapshot_came_from_user?
  end
end
