# typed: false
# frozen_string_literal: true

# Publishing management remains unavailable until its external authorization and author identity
# contracts are established. Authentication never falls back to retired local Access state or to
# the Edit cell's local principal identifier; no management action may reach a query or mutation.
module PublishingAuthorityApiEndpoint
  extend ActiveSupport::Concern
  include ProblemDetailsRendering

  EDIT_CLIENT_ID = "edit-org-ww"

  private

  attr_reader :publishing_operator

  def render_forbidden = render(json: { error: "forbidden" }, status: :forbidden)

  def render_not_found = render(json: { error: "not_found" }, status: :not_found)

  def render_bad_request = render(json: { error: "bad_request" }, status: :bad_request)

  def authenticate_publishing_caller!
    response.headers["Cache-Control"] = "no-store"
    render_problem(:service_unavailable)
  end

  def publishing_entry_class
    # The twelve fixed Publishing cells (four content families x three audiences).
    case [params[:surface], params[:audience]]
    when ["docs", "app"] then Publishing::Docs::App::Entry
    when ["docs", "com"] then Publishing::Docs::Com::Entry
    when ["docs", "org"] then Publishing::Docs::Org::Entry
    when ["help", "app"] then Publishing::Help::App::Entry
    when ["help", "com"] then Publishing::Help::Com::Entry
    when ["help", "org"] then Publishing::Help::Org::Entry
    when ["info", "app"] then Publishing::Info::App::Entry
    when ["info", "com"] then Publishing::Info::Com::Entry
    when ["info", "org"] then Publishing::Info::Org::Entry
    when ["news", "app"] then Publishing::News::App::Entry
    when ["news", "com"] then Publishing::News::Com::Entry
    when ["news", "org"] then Publishing::News::Org::Entry
    else raise ActiveRecord::RecordNotFound
    end
  end

  def publishing_entries_query
    PublishingManagementEntriesQuery.new(entry_class: publishing_entry_class)
  end

  def find_publishing_entry!(key = :entry_ref)
    publishing_entries_query.find!(public_id: params.expect(key))
  end

  def authorize_publishing_entry!(record, to:)
    authorize!(record, to:, with: PublishingEntryPolicy, context: { user: publishing_operator })
  end

  # Re-read through the cell query so every association the serializer needs is preloaded.
  def render_entry(entry, status: :ok)
    fresh = publishing_entries_query.find!(public_id: entry.public_id)
    render json: { entry: PublishingManagementEntrySerializer.detail(fresh) }, status:
  end

  def render_publishing_errors(errors, entry: nil)
    body = { errors: errors.to_h { |key, value| [key.to_s, value] } }
    if entry
      body[:entry] =
        PublishingManagementEntrySerializer.detail(publishing_entries_query.find!(public_id: entry.public_id))
    end
    render json: body, status: :unprocessable_content
  end
end
