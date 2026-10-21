# Find eligible builder and runner images on Docker Hub. We use Ubuntu/Debian instead of
# Alpine to avoid DNS resolution issues in production.
#
# https://hub.docker.com/r/hexpm/elixir/tags?page=1&name=ubuntu
# https://hub.docker.com/_/ubuntu?tab=tags
#
# This file is based on these images:
#
#   - https://hub.docker.com/r/hexpm/elixir/tags - for the build image
#   - https://hub.docker.com/_/debian?tab=tags&page=1&name=bullseye-20241022-slim - for the release image
#   - https://pkgs.org/ - resource for finding needed packages
#   - Ex: hexpm/elixir:1.17.2-erlang-27.0.1-debian-bullseye-20240701-slim
#
ARG ELIXIR_VERSION=1.18.4
ARG OTP_VERSION=28.0.2
ARG DEBIAN_VERSION=bookworm-20250811-slim

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}"

FROM ${BUILDER_IMAGE} AS builder

# install build dependencies
RUN apt-get update -y && apt-get install -y build-essential git ca-certificates curl \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# prepare build dir
WORKDIR /app

# Use single-mapped memory for the Erlang JIT to avoid QEMU segmentation faults
# when cross-building linux/amd64 images on ARM64 (Apple Silicon) hosts
ENV ERL_AFLAGS="+JMsingle true"
ENV ERL_FLAGS="+JMsingle true"

# install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# set build ENV
ARG PHX_HOST="localhost"
ARG SECRET_KEY_BASE="c3YDkogXK0SiX18Vm6xTshJpxXMoQHlE0wL0ri+WX2MmkLhPcJ9kPkhC7fWhfW9E"
ENV MIX_ENV="prod"
ENV DATABASE_PATH="/app/codice_web.db"
ENV SECRET_KEY_BASE="${SECRET_KEY_BASE}"
# Change this to your actual host if needed
ENV PHX_HOST="${PHX_HOST}" 

# build assets and compile the project
# We compile first so that phoenix_live_view generates colocated hooks
COPY assets assets
COPY priv priv
COPY comunidb comunidb
COPY lib lib
COPY entrypoint.sh ./

# install mix dependencies
COPY mix.exs mix.lock ./
COPY config config
RUN mix deps.get --only $MIX_ENV
RUN mix deps.compile
RUN mix compile

# build assets for production
RUN mix assets.deploy

# build release
RUN mix phx.gen.release
RUN mix release

# run migrations and seed data
RUN mix ecto.migrate
RUN mix run priv/repo/seeds.exs

# start a new build stage so that the final image will only contain
# the compiled release and other runtime necessities
FROM ${RUNNER_IMAGE} AS final

RUN apt-get update \
  && apt-get install -y --no-install-recommends libstdc++6 openssl libncurses6 locales ca-certificates sqlite3 libcap2-bin \
  && rm -rf /var/lib/apt/lists/*

# Set the locale
RUN sed -i '/it_IT.UTF-8/s/^# //g' /etc/locale.gen \
    && sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen \
    && locale-gen

ENV LANG=it_IT.UTF-8
ENV LANGUAGE=it_IT:it
ENV LC_ALL=it_IT.UTF-8

WORKDIR /app
RUN chown nobody /app

# set runner ENVs
ARG PHX_HOST="localhost"
ARG SECRET_KEY_BASE="c3YDkogXK0SiX18Vm6xTshJpxXMoQHlE0wL0ri+WX2MmkLhPcJ9kPkhC7fWhfW9E"
ENV MIX_ENV="prod"
ENV DATABASE_PATH="/app/codice_web.db"
ENV SECRET_KEY_BASE="${SECRET_KEY_BASE}"
ENV PHX_SERVER=true
ENV PHX_HOST="${PHX_HOST}"
ENV PHX_SCHEME="http"
ENV PORT=80

EXPOSE 80

# Only copy the final release from the build stage
COPY --from=builder --chown=nobody:root /app/_build/${MIX_ENV}/rel/codice_web ./
COPY --from=builder --chown=nobody:root /app/codice_web.db ./

# Allow non-root user (nobody) to bind to privileged port 80
RUN setcap 'cap_net_bind_service=+ep' /app/erts-*/bin/beam.smp

USER nobody

CMD ["/app/bin/server"]
