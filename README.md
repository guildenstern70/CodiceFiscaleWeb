# Codice Fiscale Web

This application allows to create the Codice Fiscale for an italian citizen.

# Setup

## Database

SQLite database is configured in config/dev.exs and created with:

    mix ecto.create

you run migrations with

    mix ecto.migrate

Seed data with

    mix run priv/repo/seeds.exs


## Dev Server

Install all dependencies with:

    mix.setup

Then you can start Phoenix server with:

    mix phx.server

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.


## Docker

Build Dockerfile with:

    docker build -t codice_web:local .

If you are using a platform different then Linux:

    docker buildx build --platform=linux/arm64 --no-cache -t codice_web:local .

Run the generated image with:

    docker run -p 4000:4000 codice_web:local

You can now browse the application at:

    http://localhost:4000

