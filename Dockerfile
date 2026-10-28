# syntax=docker/dockerfile:1
# check=error=true

# Build with: docker build -t offliner .
# Run the web server:  docker run -d -p 3000:3000 -e RAILS_MASTER_KEY=<value from config/master.key> offliner
# Run the Sidekiq worker: same image, command `bundle exec sidekiq`
# Postgres and Redis/Valkey are not in the image; point at them with DATABASE_URL and REDIS_URL.

ARG RUBY_VERSION=3.4.10
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

WORKDIR /rails

# Runtime packages. firefox-esr + geckodriver let the scraper render moose.gg
# (a Blazor page that fills in the player count client-side).
ARG GECKODRIVER_VERSION=0.37.1
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl ca-certificates libpq5 firefox-esr && \
    arch="$(uname -m)" && \
    case "$arch" in \
      x86_64) gecko_arch=linux64 ;; \
      aarch64) gecko_arch=linux-aarch64 ;; \
      *) echo "unsupported arch: $arch" >&2; exit 1 ;; \
    esac && \
    curl -fsSL "https://github.com/mozilla/geckodriver/releases/download/v${GECKODRIVER_VERSION}/geckodriver-v${GECKODRIVER_VERSION}-${gecko_arch}.tar.gz" \
      | tar -xz -C /usr/local/bin geckodriver && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development"

# Throw-away build stage to keep the final image small
FROM base AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev libyaml-dev pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

COPY . .

RUN bundle exec bootsnap precompile app/ lib/


# Final image
FROM base

COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Run as a non-root user. Firefox needs a writable HOME for its profile.
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp
USER 1000:1000

EXPOSE 3000
CMD ["./bin/rails", "server", "-b", "0.0.0.0"]
