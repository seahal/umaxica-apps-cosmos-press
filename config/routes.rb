# typed: false
# frozen_string_literal: true

Rails.application.routes.draw do
  # Press owns its publishing pages and independent staff RP.
  draw :info
  draw :news
  draw :help
  draw :docs
  draw :edit

  # Mission owns the Solid Queue job-monitoring surface (Mission Control Jobs), staff-only.
  draw :mission

  # Flipper owns the feature-flag control surface (Flipper::UI), staff-only.
  draw :flipper

  # Blazer owns the SQL exploration dashboard (Blazer::Engine), staff-only, development-only.
  draw :blazer

  # PgHero owns the PostgreSQL monitoring dashboard (PgHero::Engine), staff-only, development-only.
  draw :pghero

  # Swagger owns the rendered view of the bundled OpenAPI descriptions and the authenticated
  # endpoint that serves them (Rswag::Ui and Rswag::Api engines), staff-only, development-only.
  draw :swagger

  # Coverband owns the runtime code-execution report (Coverband::Reporters::Web), staff-only,
  # development-only, and only in the process that serves requests.
  draw :coverband

  # Any host that reached the app without matching a surface above is unknown;
  # answer it here rather than leaking a routing error.
  get "/", to: "unknown_hosts#show"
end
