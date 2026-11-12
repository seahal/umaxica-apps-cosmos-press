# typed: false
# frozen_string_literal: true

# Edit sign-out completion uses an ERB page.
#
# A signed-in session on the same origin may have left browser storage behind. `Clear-Site-Data:
# "storage"` drops sessionStorage, localStorage, IndexedDB and service-worker registrations for
# this origin, so old private state cannot be restored without asking the server; `"cache"` drops
# the HTTP cache alongside it. Authenticated responses are also `no-store` and every re-fetch is
# authenticated server-side.
#
# The Edit surface does not register a service worker.
module SignOutClearSiteData
  CLEAR_SITE_DATA = '"cache", "storage"'

  private

  def render_oidc_rp_logout_completion
    response.set_header("Clear-Site-Data", CLEAR_SITE_DATA)
    super
  end
end
