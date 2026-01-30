#
# Codice Fiscale Phoenix Web Site
# (C) 2026 Alessio Saltarin <alessiosaltarin@gmail.com>
# MIT License
#

defmodule Main do
  use Application
  
  def print_help() do
    IO.puts("Usage: codicefiscale [options]")
    IO.puts("Options:")
    IO.puts("  help       Print this help message")
    IO.puts("  version    Print the version")
    IO.puts("  builddb    Build the 'comuni' database")
  end
  
  def print_version() do
    IO.puts("Codice Fiscale v.0.1.0")
  end
  
  def compute_fiscal_code() do
    
    # Define a person as an Elixir map
    person = %{
      name: "Lucilla",
      surname: "Gaspari",
      birth_date: ~D[1975-03-23],
      birth_place: "Cuneo",
      gender: :female
    }
    
    IO.puts("Person:")
    IO.inspect(person)
    
    fiscal_code = Codicefiscale.compute(person)
    IO.puts("> CODICE FISCALE: " <> fiscal_code)
  end
  
  def build_comuni_db() do
    IO.puts("Building 'comuni' database...")
    Comuni.build_db()
  end

  def start(_type, _args) do
    IO.puts "Codice Fiscale v.0.1.0"
    IO.puts "Running in " <> File.cwd!
    arguments = System.argv()
    
    cond do
      arguments == [] -> compute_fiscal_code()
      arguments == ["help"] -> print_help()
      arguments == ["version"] -> print_version()
      arguments == ["builddb"] -> build_comuni_db()
      true -> :ok
    end
    
    
    # List all child processes to be supervised
    children = []
  
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: A.Supervisor]
    Supervisor.start_link(children, opts)
    
  end
end