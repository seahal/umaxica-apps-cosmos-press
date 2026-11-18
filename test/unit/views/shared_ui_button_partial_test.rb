# typed: false
# frozen_string_literal: true

require "test_helper"

# shared/ui/_button builds its attributes with Rails tag helpers, so Rails owns escaping and
# attribute names never come from ERB output (Herb's erb-no-output-in-attribute-name rule).
class SharedUiButtonPartialTest < ActionView::TestCase
  test "renders a plain button with the default type" do
    render partial: "shared/ui/button", locals: { label: "Go" }

    assert_dom "button[type=button]", text: "Go", count: 1
    assert_dom "button[class]", count: 0
    assert_dom "button[disabled]", count: 0
  end

  test "renders type, class, disabled and dasherized data attributes" do
    render partial: "shared/ui/button",
           locals: { label: "Go",
                     type: :submit,
                     class: "btn x",
                     disabled: true,
                     data: { action: "click->a#b", turbo_confirm: "Sure?" }, }

    assert_dom "button[type=submit][class='btn x'][disabled]", text: "Go"
    assert_dom "button[data-action='click->a#b'][data-turbo-confirm='Sure?']"
  end

  test "an empty class is omitted" do
    render partial: "shared/ui/button", locals: { label: "Go", class: "" }

    assert_dom "button[class]", count: 0
  end

  test "escapes markup in the label and quotes in the class value" do
    render partial: "shared/ui/button",
           locals: { label: %(<script>"x"</script>), class: %(a" onclick="y) }

    assert_dom "script", count: 0
    assert_dom "button[onclick]", count: 0
    assert_dom "button", text: %(<script>"x"</script>)
    assert_dom "button[class=?]", %(a" onclick="y)
  end

  test "renders a link when href is given" do
    render partial: "shared/ui/button", locals: { label: "L", href: "/p", data: { turbo: false } }

    assert_dom "a[href='/p'][data-turbo=false]", text: "L"
    assert_dom "button", count: 0
  end
end
