# typed: false
# frozen_string_literal: true

require Rails.root.join("lib/jit_session_cookie_config").to_s

# config/initializers/session_store.rb
force_secure = JitSessionCookieConfig.force_secure?

Rails.application.config.session_store(
  :cookie_store,
  **JitSessionCookieConfig.session_options(force_secure: force_secure),
)
