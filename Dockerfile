# syntax=docker/dockerfile:1
ARG ELIXIR_VERSION=1.20.4
ARG OTP_VERSION=29.1
ARG ALPINE_VERSION=3.24.1

FROM hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-alpine-${ALPINE_VERSION} AS builder

RUN apk add --no-cache build-base git nodejs npm

WORKDIR /app

ENV MIX_ENV=prod \
    LANG=C.UTF-8

RUN mix local.hex --force && mix local.rebar --force

COPY mix.exs ./
COPY lib lib
COPY site/mix.exs site/mix.lock site/
COPY site/config site/config

WORKDIR /app/site
RUN mix deps.get --only prod && mix deps.compile

WORKDIR /app
COPY assets assets
RUN cd assets && npm ci

COPY site site

WORKDIR /app/site
RUN mix compile && mix assets.deploy && mix release

FROM alpine:${ALPINE_VERSION} AS runner

ARG APK_REFRESH=0
RUN echo "apk layer built for ${APK_REFRESH}" \
    && apk upgrade --no-cache \
    && apk add --no-cache bash openssl libgcc libstdc++ ncurses-libs curl \
    && addgroup -S appgroup \
    && adduser -S appuser -G appgroup

WORKDIR /app

ENV HOME=/app \
    MIX_ENV=prod \
    PHX_SERVER=true \
    LANG=C.UTF-8 \
    DATABASE_PATH=/app/data/changelog.db

RUN mkdir -p /app/data && chown appuser:appgroup /app/data

VOLUME ["/app/data"]

COPY --from=builder --chown=appuser:appgroup /app/site/_build/prod/rel/devaction_ui_site ./

USER appuser:appgroup

EXPOSE 4000

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD curl -fsS http://127.0.0.1:4000/up || exit 1

CMD ["bin/devaction_ui_site", "start"]
