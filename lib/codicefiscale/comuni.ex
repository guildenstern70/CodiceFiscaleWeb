#
# Codice Fiscale Phoenix Web Site
# (C) 2026 Alessio Saltarin <alessiosaltarin@gmail.com>
# MIT License
#

defmodule Comuni do
  
  @comunidb "comunidb/comuni.db"
  @comunicsv "comunidb/listacomuni.csv"
  
  
  def find_comune(comune) do
    {:ok, conn} = Exqlite.Sqlite3.open(@comunidb)
    {:ok, statement} = Exqlite.Sqlite3.prepare(conn, """
    
    SELECT * FROM comuni WHERE comune = ?
    
    """)
    :ok = Exqlite.Sqlite3.bind(statement, [comune])
    {:row, result}  = Exqlite.Sqlite3.step(conn, statement)
    Exqlite.Sqlite3.close(conn)
    result
  end
  
  def find_comune_code(comune) do
    find_comune(comune)
    |> Enum.take(-1)
    |> List.first()
  end
  
  def find_comune_province(comune) do
    find_comune(comune)
    |> Enum.take(-5)
  end
  
  def build_db() do
    if check_db_exists() do
      IO.puts("Database already exists")
    else
      { comuni, _howmany } = comuni_from_csv()
      create_comuni_table()
      insert_comuni(comuni)
      IO.puts("Database created")
    end
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

  defp create_comuni_table do
    {:ok, conn} = Exqlite.Sqlite3.open(@comunidb)
    :ok = Exqlite.Sqlite3.execute(conn, """
    CREATE TABLE IF NOT EXISTS comuni 
      (id TEXT PRIMARY KEY, 
       comune TEXT, 
       provincia TEXT,
       regione TEXT,
       prefisso TEXT,
       cap TEXT,
       codice TEXT)
    """)
    Exqlite.Sqlite3.close(conn)
  end
  
  defp insert_comuni(comuni_list) do
    for comune <- comuni_list do
      insert_comune(comune)
    end
  end

  defp insert_comune(comune) do
    {:ok, conn} = Exqlite.Sqlite3.open(@comunidb)
    {:ok, statement} = Exqlite.Sqlite3.prepare(conn, """
    
    INSERT INTO comuni (
    id,
    comune, 
    provincia,
    regione,
    prefisso,
    cap,
    codice) VALUES (?, ?, ?, ?, ?, ?, ?)
    
    """)
    :ok = Exqlite.Sqlite3.bind(statement, [
          comune.id, 
          comune.comune, 
          comune.provincia, 
          comune.regione, 
          comune.prefisso, 
          comune.cap, 
          comune.codice])
    :done = Exqlite.Sqlite3.step(conn, statement)
    :ok = Exqlite.Sqlite3.close(conn)
  end
  
  defp comune_from_text_line(text) do
    [istat, nome, provincia, regione, prefisso, cap, codice, _abitanti, _link] = String.split(text, ";")
    %{id: istat, comune: nome, provincia: provincia, regione: regione, prefisso: prefisso, cap: cap, codice: codice}
  end
  
  defp check_db_exists() do
    File.exists?(@comunidb)
  end
  
  defp check_comuni_csv_exists() do
    File.exists?(@comunicsv)
  end
  
end
