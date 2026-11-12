# frozen_string_literal: true

require "test_helper"

module Edit
  module Org
    module Publishing
      module CoverageProbe
        class EntriesController < ::ApplicationController
          include ActionPolicy::Controller
          include PublishingManagementEntriesActions

          AUTHENTICATION_MODE = :open
          PUBLISHING_AUDIENCE = :app
          PUBLISHING_SURFACE = :docs

          skip_before_action :authenticate_browser_rp!, raise: false

          def csrf
            render plain: form_authenticity_token
          end
        end

        class PublicationsController < ::ApplicationController
          include ActionPolicy::Controller
          include PublishingManagementPublicationsActions

          AUTHENTICATION_MODE = :open
          PUBLISHING_AUDIENCE = :app
          PUBLISHING_SURFACE = :docs

          skip_before_action :authenticate_browser_rp!, raise: false

          def csrf
            render plain: form_authenticity_token
          end
        end

        class ArchivesController < ::ApplicationController
          include ActionPolicy::Controller
          include PublishingManagementArchivesActions

          AUTHENTICATION_MODE = :open
          PUBLISHING_AUDIENCE = :app
          PUBLISHING_SURFACE = :docs

          skip_before_action :authenticate_browser_rp!, raise: false

          def csrf
            render plain: form_authenticity_token
          end
        end
      end
    end
  end
end

class PublishingManagementActionsCoverageTest < ActionController::TestCase
  self.fixture_table_names = []

  class UnavailableAuthority
    attr_reader :calls

    def initialize
      @calls = []
    end

    def entries(page:)
      @calls << [:entries, page]
      result
    end

    def entry(ref)
      @calls << [:entry, ref]
      result
    end

    def unarchive(ref)
      @calls << [:unarchive, ref]
      result
    end

    private

    def result
      PublishingAuthorityClient::Result.new(status: :dependency, data: nil, errors: {})
    end
  end

  tests Edit::Org::Publishing::CoverageProbe::EntriesController

  setup do
    @routes = ActionDispatch::Routing::RouteSet.new
    @routes.draw do
      get "/entries" => "edit/org/publishing/coverage_probe/entries#index"
      get "/entries/csrf" => "edit/org/publishing/coverage_probe/entries#csrf"
      get "/entries/new" => "edit/org/publishing/coverage_probe/entries#new"
      get "/entries/:id" => "edit/org/publishing/coverage_probe/entries#show"
      get "/entries/:id/edit" => "edit/org/publishing/coverage_probe/entries#edit"
      get "/publications/csrf" => "edit/org/publishing/coverage_probe/publications#csrf"
      get "/archives/csrf" => "edit/org/publishing/coverage_probe/archives#csrf"
      post "/entries" => "edit/org/publishing/coverage_probe/entries#create"
      patch "/entries/:id" => "edit/org/publishing/coverage_probe/entries#update"
      delete "/entries/:entry_id/archive" => "edit/org/publishing/coverage_probe/archives#destroy"
      delete "/entries/:entry_id/publications/:id" => "edit/org/publishing/coverage_probe/publications#destroy"
    end
    @request.host = Rails.configuration.x.boot_config.fetch(:hosts).edit_staff.host
  end

  test "entry read and form actions return unavailable when the Publishing authority is unavailable" do
    assert_authority_unavailable(:index, expected_call: [:entries, 3], params: { page: "3" })
    assert_authority_unavailable(:show, expected_call: [:entry, "entry-1"], params: { id: "entry-1" })
    assert_authority_unavailable(:new, expected_call: [:entries, 1])
    assert_authority_unavailable(
      :create,
      expected_call: [:entries, 1],
      params: { entry: { title: "", summary: "", body: "", locale: "en", slug: "" } },
      verb: :post,
    )
    assert_authority_unavailable(:edit, expected_call: [:entry, "entry-1"], params: { id: "entry-1" })
  end

  test "entry update reads the target through the authority before rendering its unavailable result" do
    assert_authority_unavailable(
      :update,
      expected_call: [:entry, "entry-1"],
      params: { id: "entry-1", entry: { title: "", summary: "", body: "", lock_version: "1" } },
      verb: :patch,
    )
  end

  test "archive and publication termination return unavailable from their authority command" do
    authority = UnavailableAuthority.new
    dispatch_with_authority(
      Edit::Org::Publishing::CoverageProbe::ArchivesController, authority, :delete, :destroy,
      entry_id: "entry-1",
    )

    assert_response :service_unavailable
    assert_equal [[:unarchive, "entry-1"]], authority.calls

    authority = UnavailableAuthority.new
    dispatch_with_authority(
      Edit::Org::Publishing::CoverageProbe::PublicationsController, authority, :delete, :destroy,
      entry_id: "entry-1", id: "publication-1",
    )

    assert_response :service_unavailable
    assert_equal [[:entry, "entry-1"]], authority.calls
  end

  private

  def assert_authority_unavailable(action, expected_call:, params: {}, verb: :get)
    authority = UnavailableAuthority.new
    dispatch_with_authority(Edit::Org::Publishing::CoverageProbe::EntriesController, authority, verb, action, **params)

    assert_response :service_unavailable, action
    assert_equal [expected_call], authority.calls, action
  end

  def dispatch_with_authority(controller, authority, verb, action, **params)
    @controller = controller.new
    if %i(post patch delete).include?(verb)
      get(:csrf)
      @request.headers["Origin"] = @request.base_url
      @request.headers["X-CSRF-Token"] = response.body
    end
    PublishingAuthorityClient.stub(:new, ->(**) { authority }) do
      @controller.stub(:authorize!, ->(*_arguments, **_options) { true }) do
        public_send(verb, action, params:)
      end
    end
  end
end
