#
# Codice Fiscale Phoenix Web Site
# (C) 2026 Alessio Saltarin <alessiosaltarin@gmail.com>
# MIT License
#

defmodule CodiceWeb.StartupChecks do
  @moduledoc """
  Run lightweight checks at application startup.

  - Verifies the database is reachable.
  - Verifies the `comuni` table has > 100 rows and logs a warning otherwise.
  """

  use GenServer
  require Logger
  alias CodiceWeb.Repo

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(_) do
    # Run the potentially blocking DB check asynchronously so init is fast.
    Task.start(fn -> run_check() end)
    {:ok, %{checked: false}}
  end

  defp run_check do
    threshold = 100

    result =
      try do
        Repo.query("SELECT COUNT(*) FROM comuni")
      rescue
        e -> {:error, e}
      end

    case result do
      {:ok, %{rows: [[count]]}} when is_integer(count) ->
        log_count(count, threshold)

      {:ok, %{rows: [[count_str]]}} when is_binary(count_str) ->
        count = parse_count(count_str)
        log_count(count, threshold)

      {:error, err} ->
        Logger.error("Startup DB check failed: #{inspect(err)}")

      other ->
        Logger.error("Unexpected result from DB check: #{inspect(other)}")
    end
  end

  defp log_count(count, threshold) when count > threshold do
    Logger.info("Comuni table present with #{count} rows (threshold=#{threshold}).")
  end

  defp log_count(count, threshold) do
    Logger.warning("Comuni table row count is #{count}; expected > #{threshold}.")
  end

  defp parse_count(val) when is_binary(val) do
    case Integer.parse(val) do
      {i, _} -> i
      :error -> 0
    end
  end

  defp parse_count(val) when is_integer(val), do: val
  defp parse_count(_), do: 0
end
