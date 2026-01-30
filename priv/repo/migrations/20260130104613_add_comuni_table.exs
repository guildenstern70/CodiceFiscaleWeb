defmodule CodiceWeb.Repo.Migrations.AddComuniTable do
  use Ecto.Migration

  def up do
    create table("comuni") do
      add :istat,    :string, size: 7
      add :comune, :string, size: 200
      add :provincia, :string, size: 2
      add :regione, :string, size: 3
      add :prefisso, :string, size: 5
      add :cap, :string, size: 5
      add :codice, :string, size: 4
    end
  end

  def down do
    drop table("comuni")
  end
  
end
