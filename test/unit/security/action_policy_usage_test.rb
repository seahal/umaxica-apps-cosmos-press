# typed: false
# frozen_string_literal: true

require "test_helper"
# require "helpers/global_test_support"

class ActionPolicyUsageTest < ActiveSupport::TestCase
  self.fixture_table_names = []

  SURFACE_AUTHORIZATION_CONTEXTS = {
    Edit::Org::ApplicationController => {
      user: :current_resource,
      access_token_claims: :current_verified_access_token_claims,
    },
  }.freeze

  MUTATION_ACTIONS = %w(create update destroy).freeze

  PRIVATE_MUTATION_AUTHORIZATION_EXCEPTIONS = [
    # The Publishing CMS's 36 per-cell controllers each declare only their cell's identity
    # (PUBLISHING_SURFACE, PUBLISHING_AUDIENCE, ENTRY_CLASS) and delegate every action to a
    # shared concern (PublishingManagementEntriesActions,
    # PublishingManagementPublicationsActions, PublishingManagementArchivesActions), so this
    # scan's per-file literal match never sees the `authorize!` call the concern action makes
    # (`PublishingManagementCell#authorize_publishing!`, which always calls `authorize!(...,
    # with: PublishingEntryPolicy)`). Edit's `management_matrix_test.rb` holds that every one of
    # the 36 controllers includes the concern that calls it.
    "app/controllers/edit/org/publishing/docs/app/entries_controller.rb#create",
    "app/controllers/edit/org/publishing/docs/app/entries_controller.rb#update",
    "app/controllers/edit/org/publishing/docs/app/entries/publications_controller.rb#create",
    "app/controllers/edit/org/publishing/docs/app/entries/publications_controller.rb#destroy",
    "app/controllers/edit/org/publishing/docs/app/entries/archives_controller.rb#create",
    "app/controllers/edit/org/publishing/docs/app/entries/archives_controller.rb#destroy",
    "app/controllers/edit/org/publishing/docs/com/entries_controller.rb#create",
    "app/controllers/edit/org/publishing/docs/com/entries_controller.rb#update",
    "app/controllers/edit/org/publishing/docs/com/entries/publications_controller.rb#create",
    "app/controllers/edit/org/publishing/docs/com/entries/publications_controller.rb#destroy",
    "app/controllers/edit/org/publishing/docs/com/entries/archives_controller.rb#create",
    "app/controllers/edit/org/publishing/docs/com/entries/archives_controller.rb#destroy",
    "app/controllers/edit/org/publishing/docs/org/entries_controller.rb#create",
    "app/controllers/edit/org/publishing/docs/org/entries_controller.rb#update",
    "app/controllers/edit/org/publishing/docs/org/entries/publications_controller.rb#create",
    "app/controllers/edit/org/publishing/docs/org/entries/publications_controller.rb#destroy",
    "app/controllers/edit/org/publishing/docs/org/entries/archives_controller.rb#create",
    "app/controllers/edit/org/publishing/docs/org/entries/archives_controller.rb#destroy",
    "app/controllers/edit/org/publishing/help/app/entries_controller.rb#create",
    "app/controllers/edit/org/publishing/help/app/entries_controller.rb#update",
    "app/controllers/edit/org/publishing/help/app/entries/publications_controller.rb#create",
    "app/controllers/edit/org/publishing/help/app/entries/publications_controller.rb#destroy",
    "app/controllers/edit/org/publishing/help/app/entries/archives_controller.rb#create",
    "app/controllers/edit/org/publishing/help/app/entries/archives_controller.rb#destroy",
    "app/controllers/edit/org/publishing/help/com/entries_controller.rb#create",
    "app/controllers/edit/org/publishing/help/com/entries_controller.rb#update",
    "app/controllers/edit/org/publishing/help/com/entries/publications_controller.rb#create",
    "app/controllers/edit/org/publishing/help/com/entries/publications_controller.rb#destroy",
    "app/controllers/edit/org/publishing/help/com/entries/archives_controller.rb#create",
    "app/controllers/edit/org/publishing/help/com/entries/archives_controller.rb#destroy",
    "app/controllers/edit/org/publishing/help/org/entries_controller.rb#create",
    "app/controllers/edit/org/publishing/help/org/entries_controller.rb#update",
    "app/controllers/edit/org/publishing/help/org/entries/publications_controller.rb#create",
    "app/controllers/edit/org/publishing/help/org/entries/publications_controller.rb#destroy",
    "app/controllers/edit/org/publishing/help/org/entries/archives_controller.rb#create",
    "app/controllers/edit/org/publishing/help/org/entries/archives_controller.rb#destroy",
    "app/controllers/edit/org/publishing/info/app/entries_controller.rb#create",
    "app/controllers/edit/org/publishing/info/app/entries_controller.rb#update",
    "app/controllers/edit/org/publishing/info/app/entries/publications_controller.rb#create",
    "app/controllers/edit/org/publishing/info/app/entries/publications_controller.rb#destroy",
    "app/controllers/edit/org/publishing/info/app/entries/archives_controller.rb#create",
    "app/controllers/edit/org/publishing/info/app/entries/archives_controller.rb#destroy",
    "app/controllers/edit/org/publishing/info/com/entries_controller.rb#create",
    "app/controllers/edit/org/publishing/info/com/entries_controller.rb#update",
    "app/controllers/edit/org/publishing/info/com/entries/publications_controller.rb#create",
    "app/controllers/edit/org/publishing/info/com/entries/publications_controller.rb#destroy",
    "app/controllers/edit/org/publishing/info/com/entries/archives_controller.rb#create",
    "app/controllers/edit/org/publishing/info/com/entries/archives_controller.rb#destroy",
    "app/controllers/edit/org/publishing/info/org/entries_controller.rb#create",
    "app/controllers/edit/org/publishing/info/org/entries_controller.rb#update",
    "app/controllers/edit/org/publishing/info/org/entries/publications_controller.rb#create",
    "app/controllers/edit/org/publishing/info/org/entries/publications_controller.rb#destroy",
    "app/controllers/edit/org/publishing/info/org/entries/archives_controller.rb#create",
    "app/controllers/edit/org/publishing/info/org/entries/archives_controller.rb#destroy",
    "app/controllers/edit/org/publishing/news/app/entries_controller.rb#create",
    "app/controllers/edit/org/publishing/news/app/entries_controller.rb#update",
    "app/controllers/edit/org/publishing/news/app/entries/publications_controller.rb#create",
    "app/controllers/edit/org/publishing/news/app/entries/publications_controller.rb#destroy",
    "app/controllers/edit/org/publishing/news/app/entries/archives_controller.rb#create",
    "app/controllers/edit/org/publishing/news/app/entries/archives_controller.rb#destroy",
    "app/controllers/edit/org/publishing/news/com/entries_controller.rb#create",
    "app/controllers/edit/org/publishing/news/com/entries_controller.rb#update",
    "app/controllers/edit/org/publishing/news/com/entries/publications_controller.rb#create",
    "app/controllers/edit/org/publishing/news/com/entries/publications_controller.rb#destroy",
    "app/controllers/edit/org/publishing/news/com/entries/archives_controller.rb#create",
    "app/controllers/edit/org/publishing/news/com/entries/archives_controller.rb#destroy",
    "app/controllers/edit/org/publishing/news/org/entries_controller.rb#create",
    "app/controllers/edit/org/publishing/news/org/entries_controller.rb#update",
    "app/controllers/edit/org/publishing/news/org/entries/publications_controller.rb#create",
    "app/controllers/edit/org/publishing/news/org/entries/publications_controller.rb#destroy",
    "app/controllers/edit/org/publishing/news/org/entries/archives_controller.rb#create",
    "app/controllers/edit/org/publishing/news/org/entries/archives_controller.rb#destroy",
  ].freeze

  test "authenticated Press controllers use Action Policy with explicit local principal context" do
    SURFACE_AUTHORIZATION_CONTEXTS.each do |controller_class, expected_context|
      assert_includes controller_class.ancestors,
                      ActionPolicy::Controller,
                      "#{controller_class.name} must include ActionPolicy::Controller"
      assert_equal(
        expected_context,
        controller_class.instance_variable_get(:@authorization_targets),
        "#{controller_class.name} must authorize through its request-local verified RP principal",
      )
    end
  end

  test "authenticated surface controllers run access policy before actions" do
    SURFACE_AUTHORIZATION_CONTEXTS.each_key do |controller_class|
      before_filters =
        controller_class._process_action_callbacks.filter_map do |callback|
          callback.filter if callback.kind == :before
        end

      assert_includes before_filters,
                      :enforce_access_policy!,
                      "#{controller_class.name} must run access policy enforcement"
      assert(
        controller_class.const_defined?(:AUTHENTICATION_MODE, false) ||
        controller_class.local_authentication_mode_rules.present?,
        "#{controller_class.name} must declare an authentication mode",
      )
    end
  end

  test "application code does not use Pundit" do
    offenders = matching_lines(/\bPundit\b|\bpundit\b/, paths_under("app", "lib", "config"))

    assert_empty offenders, "Use Action Policy only. Remove Pundit references:\n#{offenders.join("\n")}"
  end

  test "application code does not use authorization bypass helpers" do
    offenders = matching_lines(/\bskip_authorization\b|\bskip_policy_scope\b/, paths_under("app", "lib", "config"))

    assert_empty offenders, "Authorization bypass helpers are forbidden:\n#{offenders.join("\n")}"
  end

  test "private mutation controller actions explicitly call authorize or document an exception" do
    offenders = private_mutation_actions_without_authorize - PRIVATE_MUTATION_AUTHORIZATION_EXCEPTIONS

    assert_empty offenders,
                 "Private mutation actions must call authorize! or be allowlisted with a " \
                 "reason:\n#{offenders.join("\n")}"
  end

  private

  def paths_under(*roots)
    roots.flat_map { |root| Rails.root.glob("#{root}/**/*") }.select { |path| File.file?(path) }
  end

  def matching_lines(pattern, paths)
    paths.flat_map do |path|
      relative_path = path.relative_path_from(Rails.root).to_s
      content = File.binread(path).encode("UTF-8", invalid: :replace, undef: :replace)

      content.each_line.with_index(1).filter_map do |line, line_number|
        "#{relative_path}:#{line_number}: #{line.strip}" if line.match?(pattern)
      end
    end
  end

  def private_mutation_actions_without_authorize
    paths_under("app/controllers").filter_map do |path|
      relative_path = path.relative_path_from(Rails.root).to_s
      content = File.binread(path).encode("UTF-8", invalid: :replace, undef: :replace)
      next unless private_controller_source?(content)

      MUTATION_ACTIONS.filter_map do |action|
        body = action_body(content, action)
        next if body.blank? || body.include?("authorize!")

        "#{relative_path}##{action}"
      end
    end.flatten.sort
  end

  def private_controller_source?(content)
    content.include?("declare_authentication_mode! :private") ||
      content.include?("AUTHENTICATION_MODE = :private")
  end

  def action_body(content, action)
    action_re = Regexp.escape(action)
    match = content.match(
      /^\s*def #{action_re}\b(?<body>[\s\S]*?)(?=^\s*def\s|^\s*private\b|^\s*protected\b|^\s*end\s*$)/,
    )
    match&.named_captures&.fetch("body")
  end
end
