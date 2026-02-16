defmodule CodiceWeb.ReleaseTasks do
  @moduledoc """
  Helper tasks to run migrations and seeds in a built release.
  This module is intended to be invoked with `bin/codice_web eval "Elixir.CodiceWeb.ReleaseTasks.migrate()"`.
  """

  @app :codice_web

  def migrate do
    start_dependencies()

    repos = Application.fetch_env!(@app, :ecto_repos)

    for repo <- repos do
      {:ok, _pid} = start_repo(repo)
      run_migrations(repo)
      run_seeds()
      stop_repo(repo)
    end
  end

  defp start_dependencies do
    Application.ensure_all_started(:logger)
    :ok
  end

  defp start_repo(repo) do
    config = repo.config()
    repo.start_link(config)
  end

  defp stop_repo(repo) do
    try do
      repo.stop()
    catch
      _, _ -> :ok
    end
  end

  defp run_migrations(repo) do
    priv = :code.priv_dir(@app) |> to_string()
    migrations_path = Path.join([priv, "repo/migrations"]) |> Path.expand()

    Ecto.Migrator.run(repo, migrations_path, :up, all: true)
  end

  defp run_seeds do
    priv = :code.priv_dir(@app) |> to_string()
    seeds = Path.join([priv, "repo/seeds.exs"]) |> Path.expand()

    if File.exists?(seeds) do
      Code.eval_file(seeds)
    end
  end
end
