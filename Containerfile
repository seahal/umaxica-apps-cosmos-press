# syntax=docker/dockerfile:1
# check=error=true
# ============================================================================
# Shared build arguments
# ============================================================================
ARG RUBY_VERSION=4.0.9
ARG DOCKER_UID=1000
ARG DOCKER_GID=1000
ARG DOCKER_USER=global
ARG DOCKER_GROUP=umaxica
ARG GITHUB_ACTIONS=""
# Deployment identifier consumed by Rails.application.revision. `.git` is
# excluded from the build context, so the Rails git fallback cannot resolve
# anything inside the image; the commit SHA has to be passed in at build time
# (`--build-arg REVISION="$(git rev-parse HEAD)"`). Empty means the revision
# endpoints report null rather than a wrong value.
ARG REVISION=""
# Node.js Active LTS (v24 "Krypton"; maintenance starts 2026-10-20). Pinned to an
# exact patch so Global and Edge cannot drift to different Node builds.
ARG NODE_VERSION=26.13.1
# Bun is pinned for reproducible builds across local containers and CI.
ARG BUN_VERSION=1.4.0

# ============================================================================
# Node.js toolchain (binaries copied into the asset image)
# ============================================================================
FROM node:${NODE_VERSION}-trixie-slim AS node-toolchain

# Bun toolchain (standalone binary copied into asset image)
# ============================================================================
FROM docker.io/oven/bun:${BUN_VERSION} AS bun-toolchain
# ============================================================================
# Production base — runtime-only dependencies
# ============================================================================
FROM docker.io/library/ruby:${RUBY_VERSION}-slim-trixie AS production-base
SHELL ["/bin/bash", "-eu", "-o", "pipefail", "-c"]
ARG DOCKER_UID
ARG DOCKER_GID
ARG DOCKER_USER
ARG DOCKER_GROUP
ENV HOME=/home/${DOCKER_USER}
ENV APP_HOME=${HOME}/main
ENV LANG=C.UTF-8 \
    IS_SANDBOX=1 \
    RAILS_ENV=production \
    RACK_ENV=production \
    BUNDLE_WITHOUT=development:test \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_APP_CONFIG=/usr/local/bundle/.bundle \
    BUNDLE_FROZEN=1 \
    BUNDLE_JOBS=4 \
    BUNDLE_RETRY=3

# Update RubyGems before installing the latest Bundler
RUN gem update --system \
    && gem install bundler

WORKDIR ${APP_HOME}

RUN if ! getent group "${DOCKER_GROUP}" >/dev/null; then \
    groupadd --gid "${DOCKER_GID}" "${DOCKER_GROUP}"; \
    fi \
    && if ! id -u "${DOCKER_USER}" >/dev/null 2>&1; then \
    useradd --uid "${DOCKER_UID}" --gid "${DOCKER_GROUP}" --home "${HOME}" --shell /usr/sbin/nologin "${DOCKER_USER}"; \
    fi \
    && mkdir -p "${APP_HOME}" "${HOME}" \
    && chown -R "${DOCKER_UID}:${DOCKER_GID}" "${HOME}"

# apt lists / archives live in BuildKit cache mounts (not in the image layer),
# so rebuilds reuse downloads while the final image stays clean.
# hadolint ignore=DL3008
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    rm -f /etc/apt/apt.conf.d/docker-clean \
    && apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends \
    ca-certificates \
    libjemalloc2 \
    libpq5 \
    libyaml-0-2 \
    tzdata \
    && rm -f /usr/local/bin/gosu /usr/local/bin/gosu-*

# ============================================================================
# Production assets — Vite/Inertia client bundles
#
# Runs on the pinned Node image rather than inside the Ruby build stage: vite-plugin-ruby reads
# config/vite.json directly, so compiling the bundles needs Node, Bun, and no Ruby.
#
# NODE_ENV is set to production here and nowhere else in the build. @vitejs/plugin-react keys the
# JSX runtime off it, so a build inheriting the development compose environment ships the React
# development runtime (jsx-dev-runtime) and its warning machinery to end users.
# ============================================================================
FROM node:${NODE_VERSION}-trixie-slim AS production-assets
ENV NODE_ENV=production \
    VITE_RUBY_MODE=production \
    CI=true \
    LEFTHOOK=0

WORKDIR /assets

# Copy the pinned Bun binary from the official release image; package resolution below is lockfile-only.
COPY --from=bun-toolchain /usr/local/bin/bun /usr/local/bin/bun

# Dependencies resolve from the Bun lockfile alone, so this layer is reused until a dependency
# changes. Dev dependencies remain installed because Vite and its plugins are required to build assets.
COPY package.json bun.lock ./
RUN --mount=type=cache,target=/root/.bun/install/cache \
    bun install --frozen-lockfile

COPY config/vite.json ./config/vite.json
COPY vite.config.ts tsconfig.json tsconfig.app.json tsconfig.node.json ./
COPY src ./src

# The manifest check catches a build that produced no entrypoints; the runtime resolves every
# `vite_typescript_tag` through it. The React-runtime check is the tripwire for a lost NODE_ENV:
# the build still succeeds in that case, it just ships the development bundle.
RUN bunx vite build --mode production \
    && test -f public/vite/.vite/manifest.json \
    && if grep -rql "jsx-dev-runtime\|jsxDEV" public/vite/assets; then \
    echo "Production bundle contains the React development JSX runtime" >&2; \
    exit 1; \
    fi

# ============================================================================
# Production build — gems + asset/bootsnap precompile
# ============================================================================
FROM production-base AS production-build
ARG DOCKER_UID
ARG DOCKER_GID

# hadolint ignore=DL3008
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    rm -f /etc/apt/apt.conf.d/docker-clean \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    libpq-dev \
    libyaml-dev \
    pkg-config \
    unzip

COPY Gemfile Gemfile.lock ./
RUN --mount=type=cache,target=/tmp/bundle-cache,uid=${DOCKER_UID},gid=${DOCKER_GID} \
    bundle config set --local cache_path /tmp/bundle-cache \
    && bundle install --jobs "${BUNDLE_JOBS}" --retry "${BUNDLE_RETRY}" \
    && bundle exec bootsnap precompile --gemfile \
    && bundle clean --force \
    && rm -rf /usr/local/bundle/cache

COPY . .

# The Vite manifest is what `vite_javascript_tag` resolves entrypoints through, so the runtime
# image cannot render a single layout without it. `public/vite` is excluded from the build context
# (.dockerignore/.containerignore) precisely so this copy is the only source of it.
COPY --from=production-assets /assets/public/vite ./public/vite

RUN install -d tmp/pids log \
    && rm -rf tmp/cache \
    && find log -type f -exec truncate -s 0 {} + \
    && rm -f tmp/pids/server.pid \
    && bundle exec bootsnap precompile app/ lib/

# ============================================================================
# Production runtime
# ============================================================================
FROM production-base AS production
ARG DOCKER_UID
ARG DOCKER_GID
ARG DOCKER_USER
ARG REVISION
ENV REVISION=${REVISION}
ENV PORT=8080 \
    RUBY_YJIT_ENABLE=1 \
    RAILS_LOG_TO_STDOUT=1 \
    RAILS_SERVE_STATIC_FILES=true \
    LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libjemalloc.so.2 \
    PATH=/usr/local/bundle/bin:${PATH}

COPY --from=production-build --chown=${DOCKER_UID}:${DOCKER_GID} /usr/local/bundle /usr/local/bundle
COPY --from=production-build --chown=${DOCKER_UID}:${DOCKER_GID} ${APP_HOME} ${APP_HOME}

# Single hardening layer: lock out root + drop privilege-escalation paths,
# create owner-only writable runtime dirs, then make app + bundle read/exec only.
# Order is preserved: writable dirs are created before the chmod 500 sweep,
# which deliberately excludes tmp/log/storage.
RUN usermod -s /usr/sbin/nologin root \
    && usermod -L root \
    && rm -f /usr/bin/sudo /usr/bin/su /usr/sbin/sudo /usr/sbin/su \
    && rm -f /usr/bin/chsh /usr/bin/chfn /usr/bin/newgrp /usr/bin/passwd /usr/bin/gpasswd \
    && find / -xdev -perm /4000 -exec chmod u-s {} + 2>/dev/null || true \
    && find / -xdev -perm /2000 -exec chmod g-s {} + 2>/dev/null || true \
    && install -d -m 700 -o "${DOCKER_UID}" -g "${DOCKER_GID}" \
    tmp tmp/pids tmp/cache tmp/sockets \
    log \
    storage \
    && find "${APP_HOME}" -mindepth 1 \
    ! -type l \
    ! -path "${APP_HOME}/tmp/*" \
    ! -path "${APP_HOME}/log/*" \
    ! -path "${APP_HOME}/storage/*" \
    -exec chmod 500 {} + \
    && find /usr/local/bundle ! -type l -exec chmod 500 {} +

USER ${DOCKER_USER}

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD ruby -rsocket -e "TCPSocket.new('127.0.0.1', Integer(ENV.fetch('PORT', '8080'))).close"

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb", "--port", "8080"]

# Omitting --target must always produce the deployable runtime image.
FROM production AS final
