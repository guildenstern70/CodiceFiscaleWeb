#
# Codice Fiscale Phoenix Web Site
# (C) 2026 Alessio Saltarin <alessiosaltarin@gmail.com>
# MIT License
#

defmodule Codicefiscale.Computer do
  @moduledoc """
  Compute the Italian Codice Fiscale (CF) number.
  """

  def compute(repo,person) do
    if !check_required_fields(person) do
      raise ArgumentError, message: "Missing required fields"
    end

    first_three =
      person.surname
      |> get_surname_consonants()

    second_three =
      person.name
      |> get_name_consonants()

    year = get_year(person.birth_date)
    month = get_month(person.birth_date)
    date = get_day(person.birth_date, person.gender)
    comune_code = get_comune_of_birth(repo, person.birth_place)
    partial = first_three <> second_three <> year <> month <> date <> comune_code
	  control_code = get_control_code(partial)
	  partial <> control_code    
  end
  
  def get_name_consonants(name) do
    name_consonants = get_consonants(name)
    name_consonants_len = length(name_consonants)

    cond do
      name_consonants_len == 0 -> "XXX"
      name_consonants_len == 1 -> get_first_consonants_one(name)
      name_consonants_len == 2 -> get_first_consonants_two(name)
      name_consonants_len == 3 -> get_surname_consonants_std(name_consonants)
      name_consonants_len > 3 -> get_name_consonants_std(name_consonants)
    end
  end

  def get_control_code(partial_fiscal_code) do
    # Check that 'partial_fiscal_code' is exactly 16 characters long
    if String.length(partial_fiscal_code) != 15 do
      raise ArgumentError, message: "Partial fiscal code must be exactly 16 characters long"
    end

    even_value =
      get_even_or_odd_chars(partial_fiscal_code, :even)
      |> Enum.map(&get_control_code_even/1)
      |> Enum.sum()

    odd_value =
      get_even_or_odd_chars(partial_fiscal_code, :odd)
      |> Enum.map(&get_control_code_odd/1)
      |> Enum.sum()

    rem(even_value + odd_value, 26)
    |> get_remainder_code
  end

  # Get even or odd characters from 'partial_fiscal_code'
  # If 'even_odd' is :even, return even characters, otherwise return odd characters
  def get_even_or_odd_chars(partial_fiscal_code, even_odd) do
    shift =
      case even_odd do
        :even -> 0
        :odd -> 1
        true -> 1
      end

    String.graphemes(partial_fiscal_code)
    |> Enum.chunk_every(2)
    |> Enum.map(fn arr -> Enum.at(arr, shift) end)
    |> Enum.filter(fn char -> char != nil end)
  end

  def get_surname_consonants(surname) do
    surname_consonants = get_consonants(surname)
    surname_len = String.length(surname)
    cond do
      surname_len == 1 -> get_first_consonants_one(surname)
      surname_len == 2 -> get_first_consonants_two(surname)
      surname_len > 2 -> get_surname_consonants_std(surname_consonants)
    end
  end

  def get_year(birthdate) do
    year = birthdate.year
    year |> Integer.to_string() |> String.slice(2..3)
  end

  def get_month(birthdate) do
    month = birthdate.month

    cond do
      month == 1 -> "A"
      month == 2 -> "B"
      month == 3 -> "C"
      month == 4 -> "D"
      month == 5 -> "E"
      month == 6 -> "H"
      month == 7 -> "L"
      month == 8 -> "M"
      month == 9 -> "P"
      month == 10 -> "R"
      month == 11 -> "S"
      month == 12 -> "T"
    end
  end

  def get_day(birthdate, gender) do
    day =
      cond do
        gender == :male -> birthdate.day
        gender == :female -> birthdate.day + 40
      end

    cond do
      day < 10 -> "0" <> Integer.to_string(day)
      day >= 10 -> Integer.to_string(day)
    end
  end

  defp check_required_fields(person) do
    required_keys = [:name, :surname, :birth_date]
    # => true
    Enum.all?(required_keys, &Map.has_key?(person, &1))
  end

  defp get_control_code_even(character) do
    cond do
      character == "A" -> 0
      character == "0" -> 0
      character == "B" -> 1
      character == "1" -> 1
      character == "C" -> 2
      character == "2" -> 2
      character == "D" -> 3
      character == "3" -> 3
      character == "E" -> 4
      character == "4" -> 4
      character == "F" -> 5
      character == "5" -> 5
      character == "G" -> 6
      character == "6" -> 6
      character == "H" -> 7
      character == "7" -> 7
      character == "I" -> 8
      character == "8" -> 8
      character == "J" -> 9
      character == "9" -> 9
      character == "K" -> 10
      character == "L" -> 11
      character == "M" -> 12
      character == "N" -> 13
      character == "O" -> 14
      character == "P" -> 15
      character == "Q" -> 16
      character == "R" -> 17
      character == "S" -> 18
      character == "T" -> 19
      character == "U" -> 20
      character == "V" -> 21
      character == "W" -> 22
      character == "X" -> 23
      character == "Y" -> 24
      character == "Z" -> 25
    end
  end

  defp get_control_code_odd(character) do
    cond do
      character == "A" -> 1
      character == "0" -> 1
      character == "B" -> 0
      character == "1" -> 0
      character == "C" -> 5
      character == "2" -> 5
      character == "D" -> 7
      character == "3" -> 7
      character == "E" -> 9
      character == "4" -> 9
      character == "F" -> 13
      character == "5" -> 13
      character == "G" -> 15
      character == "6" -> 15
      character == "H" -> 17
      character == "7" -> 17
      character == "I" -> 19
      character == "8" -> 19
      character == "J" -> 21
      character == "9" -> 21
      character == "K" -> 2
      character == "L" -> 4
      character == "M" -> 18
      character == "N" -> 20
      character == "O" -> 11
      character == "P" -> 3
      character == "Q" -> 6
      character == "R" -> 8
      character == "S" -> 12
      character == "T" -> 14
      character == "U" -> 16
      character == "V" -> 10
      character == "W" -> 22
      character == "X" -> 25
      character == "Y" -> 24
      character == "Z" -> 23
    end
  end

  defp get_remainder_code(remainder) do
    cond do
      remainder == 0 -> "A"
      remainder == 1 -> "B"
      remainder == 2 -> "C"
      remainder == 3 -> "D"
      remainder == 4 -> "E"
      remainder == 5 -> "F"
      remainder == 6 -> "G"
      remainder == 7 -> "H"
      remainder == 8 -> "I"
      remainder == 9 -> "J"
      remainder == 10 -> "K"
      remainder == 11 -> "L"
      remainder == 12 -> "M"
      remainder == 13 -> "N"
      remainder == 14 -> "O"
      remainder == 15 -> "P"
      remainder == 16 -> "Q"
      remainder == 17 -> "R"
      remainder == 18 -> "S"
      remainder == 19 -> "T"
      remainder == 20 -> "U"
      remainder == 21 -> "V"
      remainder == 22 -> "W"
      remainder == 23 -> "X"
      remainder == 24 -> "Y"
      remainder == 25 -> "Z"
    end
  end

  defp get_comune_of_birth(repo, comune) do
    Comuni.find_comune_code(repo, comune)
  end

  defp get_first_consonants_one(word) do
    upword =
      word
      |> String.upcase()

    upword <> "XX"
  end

  defp get_first_consonants_two(word) do
    upword =
      word
      |> String.upcase()

    upword <> "X"
  end

  defp get_consonants(word) do
    word
    |> String.replace(" ", "")
    |> String.upcase()
    |> String.graphemes()
    |> Enum.filter(
      &(&1 in [
          "B",
          "C",
          "D",
          "F",
          "G",
          "H",
          "J",
          "K",
          "L",
          "M",
          "N",
          "P",
          "Q",
          "R",
          "S",
          "T",
          "V",
          "W",
          "X",
          "Y",
          "Z"
        ])
    )
  end

  defp get_surname_consonants_std(surname_consonants) do
    surname_consonants
    |> Enum.take(3)
    |> Enum.join()
  end

  defp get_name_consonants_std(name_consonants) do
    [
      Enum.at(name_consonants, 0),
      Enum.at(name_consonants, 2),
      Enum.at(name_consonants, 3)
    ]
    |> Enum.join()
  end

end
