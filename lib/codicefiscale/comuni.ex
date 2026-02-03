#
# Codice Fiscale Phoenix Web Site
# (C) 2026 Alessio Saltarin <alessiosaltarin@gmail.com>
# MIT License
#

defmodule Codicefiscale.Comuni do
  
  @comunicsv "comunidb/listacomuni.csv"
  
  def find_comune_details(repo, comune) do
    {:ok, result} = repo.query("SELECT * FROM comuni WHERE comune = $1", [comune])
    case result.rows do
      [] -> nil
      _ -> List.first(result.rows)
    end
  end

  def get_all_comuni(repo) do
    {:ok, result} = repo.query("SELECT comune FROM comuni ORDER BY comune ASC", [])
    Enum.map(result.rows, fn [comune] -> comune end)
  end
  
  def find_comune_code(repo, comune) do
    find_comune_details(repo, comune)
    |> Enum.at(7)
  end
  
  def find_comune_province(repo, comune) do
    find_comune_details(repo, comune)
    |> Enum.take(-5)
    |> List.first()
  end
  
  def build_db(repo) do
    { comuni, _howmany } = comuni_from_csv()
    insert_comuni(repo, comuni)
    IO.puts("Database COMUNI created")
  end
  
  def comuni_from_csv() do
    if check_comuni_csv_exists() == true do
      {:ok, file} = File.read(@comunicsv)      
      comuni =file
      |> String.split("\n")
      |> Enum.filter(&(&1 != ""))
      |> Enum.map(&comune_from_text_line/1)
      {comuni, length(comuni)}
    else
      IO.puts("CSV file not found.")
      {[], :file_not_found}
    end
  end
  
  defp insert_comuni(repo, comuni_list) do
    for comune <- comuni_list do
      insert_comune(repo, comune)
    end
  end

  defp insert_comune(repo, comune) do
    {:ok, _result} = repo.query("""
    
    INSERT INTO comuni (
    istat,
    comune, 
    provincia,
    regione,
    prefisso,
    cap,
    codice) VALUES ($1, $2, $3, $4, $5, $6, $7)
    
    """, [
          comune.istat, 
          comune.comune, 
          comune.provincia, 
          comune.regione, 
          comune.prefisso, 
          comune.cap, 
          comune.codice])

  end
  
  defp comune_from_text_line(text) do
    [istat, nome, provincia, regione, prefisso, cap, codice, _abitanti, _link] = String.split(text, ";")
    %{istat: istat, comune: nome, provincia: provincia, regione: regione, prefisso: prefisso, cap: cap, codice: codice}
  end
   
  defp check_comuni_csv_exists() do
    File.exists?(@comunicsv)
  end
  
end
