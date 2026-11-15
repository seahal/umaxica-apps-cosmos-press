# frozen_string_literal: true

module PublishingFamilyTaxonomyAssignment
  extend ActiveSupport::Concern

  class << self
    public

    def configure(model_class)
      model_class.class_eval do
        family = name.deconstantize
        belongs_to :vocabulary, class_name: "#{family}::Vocabulary"
        belongs_to :taxonomy_term, class_name: "#{family}::TaxonomyTerm"

        validates :locale, presence: true
        validates :vocabulary_kind, inclusion: { in: ->(record) { [record.class.expected_kind] } }
      end
    end
  end

  class_methods do
    def expected_kind = raise(NotImplementedError, "#{name} must declare expected_kind")
  end
  public

  def structural_kind = Publishing::TaxonomyKind.fetch(vocabulary_kind)
end
