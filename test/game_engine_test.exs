defmodule GameEngineTest do
  use ExUnit.Case
  alias Wordlex.GameEngine

  test "letter_map" do
    map =
      GameEngine.new("sugar")
      |> GameEngine.resolve("saper")
      |> GameEngine.resolve("cases")
      |> GameEngine.resolve("suamr")
      |> GameEngine.letter_map()

    assert map == %{correct: ["R", "S", "U"], incorrect: ["A"], invalid: ["C", "E", "M", "P"]}
  end

  describe "serialize/deserialize" do
    test "deserialize returns the same game" do
      game = GameEngine.new("sugar") |> GameEngine.resolve("sumar")
      assert game == game |> GameEngine.serialize() |> GameEngine.deserialize()
    end

    test "serialize" do
      serialized_game =
        GameEngine.new("sugar") |> GameEngine.resolve("sumar") |> GameEngine.serialize()

      assert %{"word" => "SUGAR", "guesses" => ["SUMAR"], "over?" => false, "result" => "playing"} =
               serialized_game
    end
  end
end
