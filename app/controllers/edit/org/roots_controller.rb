# typed: false
# frozen_string_literal: true

module Edit
  module Org
    class RootsController < Edit::Org::ApplicationController
      AUTHENTICATION_MODE = :open

      allow_browser versions: :modern

      public

      def index
        @region = RequestContextContract.normalize_region(params[:ri])
        response.headers["Cache-Control"] = "private, no-store"
      end
    end
  end
end
