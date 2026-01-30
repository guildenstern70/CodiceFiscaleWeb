#
# Codice Fiscale Phoenix Web Site
# (C) 2026 Alessio Saltarin <alessiosaltarin@gmail.com>
# MIT License
#

defmodule CodicefiscaleTest do
  use ExUnit.Case
  use CodiceWebWeb.ConnCase

  def setup do
    # Seed the database with comuni if not already seeded
    {:ok, result} = CodiceWeb.Repo.query("SELECT COUNT(*) FROM comuni")
    [ [count] ] = result.rows
    if count == 0 do
        IO.puts("Seeding COMUNI table...")
        Codicefiscale.Comuni.build_db(CodiceWeb.Repo)
    else
        IO.puts("COMUNI table already seeded.")
    end
  end

  test "Normal three consonants surname" do
    assert Codicefiscale.Computer.get_surname_consonants("Saltarin") == "SLT"
  end

  test "Normal two consonants surname" do
    assert Codicefiscale.Computer.get_surname_consonants("Bo") == "BXO"
  end

  test "Normal two consonants name" do
    assert Codicefiscale.Computer.get_name_consonants("Mino") == "MNI"
  end

  test "Normal one consonant surname" do
    assert Codicefiscale.Computer.get_surname_consonants("A") == "AXX"
  end
  
  test "Consonants name with len <=3" do
    assert Codicefiscale.Computer.get_name_consonants("Alessio") == "LSS"
  end
  
  test "Consonants name with len >3" do
    assert Codicefiscale.Computer.get_name_consonants("Lucilla Loretta") == "LLL"
  end
  
  test "Birth year" do
    assert Codicefiscale.Computer.get_year(Date.new!(1990, 1, 1)) == "90"
  end
  
  test "Birth month" do
    assert Codicefiscale.Computer.get_month(Date.new!(1970, 8, 26)) == "M"
  end
  
  test "Birth day" do
    assert Codicefiscale.Computer.get_day(Date.new!(1970, 8, 26), :male) == "26"
    assert Codicefiscale.Computer.get_day(Date.new!(1970, 8, 26), :female) == "66"
  end

  test "Birth comune code" do
    assert Codicefiscale.Computer.get_comune_of_birth(CodiceWeb.Repo, "Milano") == "F205"
    assert Codicefiscale.Computer.get_comune_of_birth(CodiceWeb.Repo, "Cuneo") == "D205"
  end

    test "Comune province" do
    assert Codicefiscale.Comuni.find_comune_province(CodiceWeb.Repo, "Milano") == "MI"
    assert Codicefiscale.Comuni.find_comune_province(CodiceWeb.Repo, "Cuneo") == "CN"
  end
  
  test "Fiscal Code Alessio" do
    # Define a person as an Elixir map
    person = %{
      name: "Alessio",
      surname: "Saltarin",
      birth_date: ~D[1970-08-26],
      birth_place: "Milano",
      gender: :male
    }
    assert Codicefiscale.Computer.compute(CodiceWeb.Repo, person) == "SLTLSS70M26F205X"
  end  
  
  test "Fiscal Code Lucilla" do
    person = %{
      name: "Lucilla",
      surname: "Gaspari",
      birth_date: ~D[1975-03-23],
      birth_place: "Cuneo",
      gender: :female
    }
    assert Codicefiscale.Computer.compute(CodiceWeb.Repo, person) == "GSPLLL75C63D205T"
  end  

  test "Fiscal Code Giovanna" do
    person = %{
      name: "Giovanna",
      surname: "Sementi",
      birth_date: ~D[2004-01-28],
      birth_place: "Bardonecchia",
      gender: :female
    }
    assert Codicefiscale.Computer.compute(CodiceWeb.Repo, person) == "SMNGNN04A68A651E"
  end

    test "Fiscal Code Mino" do
    person = %{
      name: "Mino",
      surname: "Santanastasio",
      birth_date: ~D[1988-12-28],
      birth_place: "Ceresole Reale",
      gender: :male
    }
    assert Codicefiscale.Computer.compute(CodiceWeb.Repo, person) == "SNTMNI88T28C505N"
  end  
  
  test "Control Code" do
    assert Codicefiscale.Computer.get_control_code("SLTLSS70M26F205") == "X"
  end
  
end