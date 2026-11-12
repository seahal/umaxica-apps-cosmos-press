# typed: false
# frozen_string_literal: true

require "test_helper"

# Retained surface templates link their own Vite stylesheets. These assertions read the templates
# and sources directly, so they need neither a Vite build nor a manifest.
class ViteEntrypointContractTest < ActiveSupport::TestCase
  # CSS carries the same boundary: one FQDN links one surface stylesheet, and that
  # file names its own `@source` roots, so a utility generated for another surface's markup cannot
  # reach this one. A layout linking a second surface's stylesheet would break that silently.
  VIEW_ROOT = Rails.root.join("app/views")
  STYLESHEET_ROOT = Rails.root.join("src/styles")
  SURFACE_STYLESHEET_ROOT = Rails.root.join("src/styles/surfaces")
  PAGE_ROOT = Rails.root.join("src/pages")
  RETAINED_SURFACES = %w(edit/org).freeze
  SURFACE_STYLESHEET_REFERENCE = /vite_stylesheet_tag\s+"~\/styles\/surfaces\/([^"]+)"/

  test "every template links only the surface stylesheet belonging to its own surface" do
    linked = surface_stylesheet_references

    assert_predicate linked, :any?, "expected the templates to link surface stylesheets"

    linked.each do |template, names|
      family, surface = template_surface(template)

      assert_equal ["#{family}_#{surface}.css"], names,
                   "#{template} must link only src/styles/surfaces/#{family}_#{surface}.css"
      assert_path_exists SURFACE_STYLESHEET_ROOT.join("#{family}_#{surface}.css")
    end
  end

  test "every surface stylesheet is linked by a template" do
    referenced = surface_stylesheet_references.values.flatten.uniq
    present = Dir.glob(SURFACE_STYLESHEET_ROOT.join("*.css")).map { |path| File.basename(path) }

    assert_equal present.sort, referenced.sort,
                 "every surface stylesheet must be linked, and every link must resolve to a file"
  end

  # There is no aggregate stylesheet: every partial reaches the browser because a surface stylesheet
  # imports it. A partial nobody imports is either dead or, worse, an umbrella file waiting to be
  # linked by a layout again, which is how one surface's rules used to reach every other.
  test "every shared stylesheet is imported by a surface stylesheet" do
    surfaces = Dir.glob(SURFACE_STYLESHEET_ROOT.join("*.css")).map { |path| File.read(path) }
    partials = Dir.glob(STYLESHEET_ROOT.join("*.css")).map { |path| File.basename(path) }

    assert_predicate partials, :any?, "expected shared stylesheets under src/styles"

    partials.each do |partial|
      assert surfaces.any? { |contents| contents.include?(%(@import "../#{partial}";)) },
             "src/styles/#{partial} is imported by no surface stylesheet"
    end
  end

  # Line breaking is language behaviour, not surface behaviour, so `base.css` owns it for all
  # retained surfaces. A surface stylesheet redefining it would silently give
  # one FQDN different kinsoku from the rest, and the last chunk emitted would decide the winner.
  LINE_BREAKING_PROPERTIES = %w(line-break word-break overflow-wrap).freeze

  test "the Japanese line breaking baseline lives only in base.css" do
    base = STYLESHEET_ROOT.join("base.css").read

    LINE_BREAKING_PROPERTIES.each do |property|
      assert_match(
        /^\s*#{Regexp.escape(property)}:/, base,
        "src/styles/base.css must declare #{property} for every surface",
      )
    end
    assert_includes base, ":lang(ja) {",
                    "src/styles/base.css must scope line breaking to Japanese"

    others = Dir.glob(STYLESHEET_ROOT.join("**/*.css")).reject { |path| File.basename(path) == "base.css" }

    others.each do |path|
      contents = File.read(path)

      LINE_BREAKING_PROPERTIES.each do |property|
        assert_no_match(
          /^\s*#{Regexp.escape(property)}:/, contents,
          "#{path} must not redefine #{property}; base.css owns line breaking",
        )
      end
    end
  end

  # `source(none)` is what turns off Tailwind's automatic source detection. Without it Tailwind
  # scans the whole Vite root and every surface stylesheet ends up carrying every other surface's
  # utilities, which is the leak these files exist to prevent.
  test "every surface stylesheet scopes Tailwind to its own sources" do
    Dir.glob(SURFACE_STYLESHEET_ROOT.join("*.css")).each do |path|
      stylesheet = Pathname.new(path)
      family, surface = stylesheet.basename(".css").to_s.split("_")
      contents = stylesheet.read

      assert_includes contents, %(@import "tailwindcss" source(none);),
                      "#{stylesheet} must disable Tailwind automatic source detection"

      own_pages = "#{family}/#{surface}"

      if PAGE_ROOT.join(own_pages).directory?
        assert_includes contents, %(@source "../../pages/#{own_pages}";),
                        "#{stylesheet} must scan its own page directory"
      end

      foreign = contents.scan(%r{@source "\.\./\.\./pages/([^"]+)";}).flatten - [own_pages]

      assert_empty foreign, "#{stylesheet} must not scan another surface's pages"
    end
  end

  private

  def surface_stylesheet_references
    Dir.glob(VIEW_ROOT.join("**/*.html.erb")).each_with_object({}) do |path, references|
      template = Pathname.new(path)
      next unless RETAINED_SURFACES.include?(template_surface(template).join("/"))

      names = File.read(path).scan(SURFACE_STYLESHEET_REFERENCE).flatten
      references[template] = names if names.any?
    end
  end

  # Layouts live at layouts/<family>/<surface>/, and a template that owns its whole document lives
  # at <family>/<surface>/. Both name the surface in the first two segments once `layouts/` is gone.
  def template_surface(template)
    relative = template.relative_path_from(VIEW_ROOT).each_filename.to_a
    relative.shift if relative.first == "layouts"
    relative.first(2)
  end
end
