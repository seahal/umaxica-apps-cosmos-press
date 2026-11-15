# typed: false
# frozen_string_literal: true

module ApplicationHelper
  # Brand title editions are the content audience hosts served by this application.
  BRAND_TLD_LABELS = %w(app com org).freeze
  public

  def brand_tld
    label = request.host.to_s.downcase.split(".").reverse.find { |part| BRAND_TLD_LABELS.include?(part) }

    unless label
      raise ArgumentError, "Cannot derive a brand TLD from host #{request.host.inspect}; " \
                           "expected one of #{BRAND_TLD_LABELS.join(", ")} among its labels"
    end

    label.upcase
  end

  def page_title(title = nil)
    if title.present?
      content_for(:page_title, title)
      title
    else
      # Brand and TLD are a locale-independent contract owned by the layout's
      # meta-tags `site:` value, so there is no translated default here. A page
      # without a title renders the site title alone, which is the root contract.
      content_for(:page_title)
    end
  end
end
