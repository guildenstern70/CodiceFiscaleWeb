# Codice Fiscale Web

This application allows to create the Codice Fiscale for an italian citizen.

# Setup

Load dependencies with

  mix deps.get

## Database

SQLite database is configured in config/dev.exs and created with:

  mix ecto.create

you run migrations with

  mix ecto.migrate

Seed data with

  mix run priv/repo/seeds.exs


## Dev Server

Setup everything with:

  mix setup

Build all assets with:

  mix assets.build

Then you can start Phoenix server with:

  mix phx.server

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

If you are getting an error saying that "app.css" cannot be found, and you are using MacOS, launch:

  codesign -s - --force _build/tailwind-*


## Docker

Build Dockerfile with:

    docker build -t codice_web:local .

If you are using a platform different then Linux:

    docker buildx build --platform=linux/arm64 --no-cache -t codice_web:local .

Run the generated image with:

    docker run -p 4000:4000 codice_web:local

You can now browse the application at:

    http://localhost:4000

When deploying to production or a cloud environment, pass `PHX_HOST` (and optionally `PORT`, `SECRET_KEY_BASE`):

    docker run -e PHX_HOST="example.com" -e PORT=4000 -p 4000:4000 codice_web:local

