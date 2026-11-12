# frozen_string_literal: true

if ENV["COVERAGE"] == "true"
  # `require "simplecov"` already loads ./.simplecov, and that file loads the
  # "rails" profile along with the rest of the configuration. Passing the
  # profile to `start` as well would apply it a second time (only duplicating
  # filters, but splitting the configuration across two places). Keep .simplecov
  # as the single source of configuration and let `start` just begin tracking.
  require "simplecov"
  SimpleCov.start
end

ENV["RAILS_ENV"] ||= "test"
# Host names are deliberately NOT set here. This file is read after the application has
# already booted whenever the runner boots first (`bin/rails test` with no path argument,
# which is the documented command), and config/application.rb freezes
# Rails.configuration.x.boot_config from ENV at boot. An assignment made here therefore
# reaches ENV but never boot_config, leaving two disagreeing sources of truth for the same
# host and making results depend on how the suite was invoked. Host configuration belongs
# to the process environment (compose.yaml, the CI job env), which is set before boot.
# test/config/host_configuration_consistency_test.rb fails loudly if the two ever diverge.
ENV["SMTP_FROM_ADDRESS_APP"] = "from@umaxica.app"
RubyVM::YJIT.enable if defined?(RubyVM::YJIT)

require_relative "../config/environment"

# Build the test-mode Vite assets before anything renders a view.
#
# `config/vite.json` sets `"autoBuild": false` for test, and `/public/vite*` is gitignored, so
# nothing else in the repository guarantees that `public/vite-test` exists or is current. Every
# layout under `app/views/layouts` calls `vite_stylesheet_tag`/`vite_typescript_tag`, and
# `ViteRuby::Manifest#lookup!` raises from inside view rendering when an entry is absent, so a
# fresh checkout, a CI runner, or a run made after editing `src/` failed with an error naming an
# entrypoint instead of the missing build. Building here keeps that dependency explicit and
# satisfied in every environment.
#
# Placement matters: this runs in the parent process, before
# `ActiveSupport::TestCase.parallelize` forks workers, so one build serves the whole run instead
# of every worker racing to write the same output directory. `ViteRuby::Builder#build` compares a
# digest of the watched files against `tmp/cache/vite/last-build-test.json` and skips the Vite
# call when nothing changed, so a repeat run pays only for the digest.
unless ViteRuby.commands.build
  abort <<~MESSAGE
    Vite test-mode build failed, so public/vite-test has no usable manifest and every test that
    renders a layout would fail on a missing entrypoint. See the Vite output above; the same build
    runs standalone as `bunx vite build --mode test`.
  MESSAGE
end

require "rails/test_help"
# `Minitest.load(:test_prof)` only requires the Minitest reporter shims
# (`lib/minitest/test_prof_plugin.rb`); it does not load the TestProf recipe classes
# (`TestProf::EventProf`, `TestProf::StackProf`, `TestProf::MinitestSample`, ...), which live
# behind the gem's top-level `require "test_prof"` entrypoint. Loading them here only defines
# classes and registers `TestProf.activate` hooks that stay inert unless their env var
# (`EVENT_PROF`, `TEST_STACK_PROF`, `SAMPLE`, ...) is set, so this carries no cost for an
# ordinary `bin/rails test` run.
require "test_prof"
Minitest.load(:test_prof)
# `MinitestSample` (backs `SAMPLE`/`SAMPLE_GROUPS`) is a recipe, not part of the top-level
# `test_prof` require above, and must be loaded explicitly like any other TestProf recipe.
require "test_prof/recipes/minitest/sample"
require_relative "support/parallel_test_database_cloner"
require_relative "support/publishing_content_helper"
require_relative "support/oidc_state_test_support"
require_relative "support/form_action_policy_helper"
require_relative "support/fetch_metadata_defaults"
require_relative "support/outbound_http_guard"
require_relative "support/outbound_http_stub"
require_relative "support/valkey_test_isolation"
require_relative "support/set_cookie_assertions"
require_relative "support/withheld_assertions"
require_relative "support/cookie_jar_helper"
require_relative "support/oidc_id_token_fixture_helper"
require_relative "support/strict_loading_association_preloader"
require_relative "support/public_id_fixed_length_assertions"
require_relative "support/rp_cell_session_helper"

module AuthenticationHarness
  include RpCellSessionHelper
  include OidcIdTokenFixtureHelper

  TEST_BROWSER_USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) " \
                            "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

  def host_headers(host = nil)
    host_value = host || (respond_to?(:request, true) ? request&.host : nil) || ENV["DEFAULT_URL_HOST"]
    headers = { "Client-Agent" => TEST_BROWSER_USER_AGENT }
    headers["Host"] = host_value if host_value.present?
    headers
  end

  def bearer_headers(token, host: nil, headers: {})
    host_headers(host).merge(headers).merge("Authorization" => "Bearer #{token}")
  end
end

module ActiveSupport
  class TestCase
    include AuthenticationHarness
    include WithheldAssertions
    include CookieJarHelper
    include PublishingContentHelper
    include FormActionPolicyHelper
    include OutboundHttpStub
    include PublicIdFixedLengthAssertions

    # Physical cores, not logical processors (SMT/vCPUs): measured on a 16-core/32-thread host --
    # `PARALLEL_WORKERS=32` (one per logical thread) took 37s on a 3000-test subset versus 22-24s
    # at 8 or 16 workers, because that many forked Rails processes plus Postgres itself oversubscribe
    # the physical cores and thrash instead of parallelizing further. See
    # docs/guides/test-profiling.md.
    #
    # A coverage run uses the same workers as any other run. `.simplecov` sets
    # `merge_subprocesses true`, so SimpleCov hooks `Process._fork` and each worker records and
    # writes its own resultset for the parent to merge; before that setting existed the run had to
    # be pinned to a single worker or the forked workers' coverage was lost.
    parallel_workers = Integer(ENV.fetch("PARALLEL_WORKERS") { Concurrent.physical_processor_count.to_s }, 10)
    raise ArgumentError, "PARALLEL_WORKERS must be positive" unless parallel_workers.positive?

    fixtures :all
    ValkeyTestIsolation.install!
    ParallelTestDatabaseCloner.install!(workers: parallel_workers)
    parallelize(workers: parallel_workers, parallelize_databases: false)

    # Rate-limit uses KVS Valkey namespaced by run and worker. Reset any
    # with_rate_limit_counters swap, then delete this worker's keys so counters
    # do not leak into the next case. Application cache is MemoryStore.
    setup do
      Rails.configuration.x.rate_limit.fetch(:store).reset!
      Rails.cache.clear
      ValkeyTestIsolation.cleanup_worker_keys!
    end

    # Same reasoning for the per-FQDN availability kill switch: it fails closed, so every served
    # FQDN is on by default here and a test that wants a surface switched off disables it itself.
    setup do
      FqdnAvailabilityRegistry.flag_names.each { |feature| Flipper.enable(feature) }
    end

    # I18n.locale is thread-local and is set by controller `set_locale`
    # before_actions during integration/controller tests. Those tests share
    # worker processes with model tests, so a request that leaves I18n.locale
    # at, e.g., :en would make a later model test read English validation
    # messages where it expects the default locale. Reset to the default after
    # every test so locale never leaks across the shared process.
    teardown { I18n.locale = I18n.default_locale } # rubocop:disable Rails/I18nLocaleAssignment

    # ENV is process-global and shared by every test a worker runs. Many integration helpers
    # (load_jump_rt_env!) write JWT_<NAMESPACE>_* without restoring them, and the local keyset
    # installer rejects such values, so a later test failed depending on seed order. Snapshot
    # ENV before each test and restore it afterwards so no assignment outlives its test.
    setup { @env_snapshot_before_test = ENV.to_h }
    teardown { ENV.replace(@env_snapshot_before_test) if @env_snapshot_before_test }

    # Class-level form of `with_rate_limit_counters`: a test case whose whole
    # subject is rate limiting declares this once and every test in it runs
    # against a deterministic MemoryStore. The per-test `setup` in the base
    # class already reset the store, and installing a fresh MemoryStore here
    # keeps buckets independent between tests in the same file.
    def self.rate_limit_counters!
      setup do
        Rails.configuration.x.rate_limit.fetch(:store).backend =
          ActiveSupport::Cache::MemoryStore.new
      end
    end

    # Opt a rate-limit-focused test into a deterministic in-process MemoryStore.
    # The default test store is namespaced Valkey; MemoryStore is still used when
    # a case needs time-travelled windows without talking to KVS.
    #
    # MemoryStore honors expires_in against Time.current, so window resets are
    # asserted by travelling time rather than sleeping.
    def with_rate_limit_counters(store = ActiveSupport::Cache::MemoryStore.new, &)
      Rails.configuration.x.rate_limit.fetch(:store).with(store, &)
    end

    # Rails.cache is already MemoryStore in test. This helper still swaps a
    # fresh store for cache-behavior tests that need an empty isolated instance.
    def with_application_cache(store = ActiveSupport::Cache::MemoryStore.new)
      previous = Rails.cache
      Rails.cache = store
      yield store
    ensure
      Rails.cache = previous
    end
  end
end
