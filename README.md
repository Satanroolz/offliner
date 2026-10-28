# Offliner

Offliner records how many players are on the moose.gg "US Main" server over time. Every 30 minutes a background job reads the current player count, and stores it in Postgres.

The project is in early development: data collection works end to end, but there are no endpoints for viewing the it yet. Rails runs in API-only mode (no views or asset pipeline), and a frontend service may be added in the future.

## How it works

- `MoosePlayerCountScraper` ([app/services/moose_player_count_scraper.rb](app/services/moose_player_count_scraper.rb)) loads a server page such as https://moose.gg/servers/us-main with Selenium and headless Firefox. The scraper waits up to 30 seconds for the "Players" card to render and parses the current count from text like "148 / 200".
- `ScrapePlayerCountJob` ([app/jobs/scrape_player_count_job.rb](app/jobs/scrape_player_count_job.rb)) is a Sidekiq job that runs the scraper and saves a `PlayerCount` record. It takes a server name (default `us-main`) and retries up to 3 times on failure.
- `config/schedule.yml` runs the job for `us-main` with sidekiq-cron every 30 minutes (UTC). To track another server, add another entry with a different `args`. The schedule is loaded when the Sidekiq server starts.
- `PlayerCount` stores `server` (the moose.gg server name, such as `us-main`), `count`, `started_at` and `ended_at` (the scrape window), plus the usual timestamps. `(server, started_at)` is indexed.

The Rails app currently only exposes the health check at `/up`.

## Stack

- Ruby 3.4.10, Rails 8.1 (API-only)
- PostgreSQL
- Redis or Valkey (Sidekiq)
- Sidekiq 8 with sidekiq-cron
- Selenium WebDriver, Firefox and geckodriver
- RSpec for tests
- Sorbet for type checking, RuboCop with the Shopify style for linting

## Running with Docker Compose

This is the easiest way to run the full stack, since the image bundles Firefox and geckodriver.

```sh
docker compose up --build
```

This starts Postgres 17, Valkey 8, a one-shot `migrate` service (`db:prepare`), the Rails server on http://127.0.0.1:3000, and a Sidekiq worker that runs the cron schedule.

The defaults in [compose.yaml](compose.yaml) are for local use only. Override `SECRET_KEY_BASE`, `POSTGRES_PASSWORD` and `RAILS_LOG_LEVEL` through a `.env` file or the environment for anything else.

To look at the collected data:

```sh
docker compose exec web ./bin/rails runner 'puts PlayerCount.order(:started_at).last(10).map { |p| [p.server, p.started_at, p.count].join("  ") }'
```

## Local development

Prerequisites: Ruby 3.4.10, PostgreSQL, Redis or Valkey, and Firefox. geckodriver is downloaded automatically by Selenium Manager if it is not on your `PATH`.

```sh
bin/setup --skip-server   # install gems and prepare the database
bin/dev                   # start the Rails server
bundle exec sidekiq       # in a second terminal: worker plus cron schedule
```

Sidekiq reads its Redis connection from `REDIS_URL` and defaults to `redis://localhost:6379/0`.

Rake tasks for working with the scraper without waiting for the schedule:

```sh
bin/rails player_count:now       # scrape and store a count immediately, no Sidekiq
bin/rails player_count:enqueue   # enqueue the Sidekiq job
bin/rails "player_count:now[us-monthly]"   # either task takes an optional server name
```

## Tests and checks

```sh
bundle exec rspec    # test suite (writes a coverage report to coverage/index.html)
bin/rubocop          # lint (Shopify Ruby style)
bundle exec srb tc   # Sorbet type check
bin/brakeman         # static security analysis
bin/bundler-audit    # gem vulnerability audit
bin/ci               # CI steps from config/ci.rb
```

Code style follows the [Shopify Ruby style guide](https://ruby-style-guide.shopify.dev/) through `rubocop-shopify`, with RSpec for tests. Run `bin/rubocop -a` to autocorrect.

The app code is type-checked with [Sorbet](https://sorbet.org/) (`# typed: true` plus `sig` annotations). RBI files live in `sorbet/rbi`. After changing gems or the schema, regenerate them with `bundle exec tapioca gem` and `bundle exec tapioca dsl`.

GitHub Actions runs the security scans, lint and tests on every pull request and on pushes to `main` (see [.github/workflows/ci.yml](.github/workflows/ci.yml)).

## Deployment

The [Dockerfile](Dockerfile) builds a production image that includes Firefox and geckodriver. Run the image as two containers, one for the web server and one for the Sidekiq worker:

- web: the default command, serves Rails on port 3000
- worker: `bundle exec sidekiq`

Postgres and Redis or Valkey are not part of the image. Provide them through these environment variables:

| Variable | Purpose |
| --- | --- |
| `DATABASE_URL` | Postgres connection string |
| `REDIS_URL` | Redis or Valkey connection string for Sidekiq |
| `RAILS_MASTER_KEY` or `SECRET_KEY_BASE` | Rails secrets |

Run `bin/rails db:prepare` before starting the services. Run only one Sidekiq process with the cron schedule, or each replica will enqueue its own copy of the job. The Sidekiq container needs extra shared memory for Firefox (`shm_size: 1gb` in the compose file).

## Known limitations and next steps

- No JSON endpoints yet for the collected data, and no frontend. Reading it from another origin will also need CORS configured (for example with `rack-cors`).
- The scraper depends on the current moose.gg page markup (the `rm-section-title` "Players" card). A site redesign will break it, and the job will fail with `MoosePlayerCountScraper::ScrapeError`.
- Only `us-main` is scheduled. Other servers work (the scraper builds the URL from the server name) but each needs its own schedule entry, and the page markup is assumed to match.
- No alerting when scrapes fail repeatedly.
