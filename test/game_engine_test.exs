defmodule GameEngineTest do
  use ExUnit.Case
  alias Wordlex.GameEngine

  describe "letter map" do
    test "letter_map distribution" do
      map =
        "sugar"
        |> GameEngine.new()
        |> GameEngine.resolve("saper")
        |> GameEngine.resolve("cases")
        |> GameEngine.resolve("suamr")
        |> GameEngine.letter_map()

      assert map == %{correct: ["R", "S", "U"], incorrect: ["A"], invalid: ["C", "E", "M", "P"]}
    end

    test "letter_map handles duplicated letters in guess" do
      map =
        "RATED"
        |> GameEngine.new()
        |> GameEngine.resolve("tyued")
        |> GameEngine.resolve("qrtdd")
        |> GameEngine.letter_map()

      assert map == %{correct: ["D", "E", "T"], incorrect: ["R"], invalid: ["Q", "U", "Y"]}
    end

    test "letter_map handles solution with duplicated letters" do
      map =
        "ASCII"
        |> GameEngine.new()
        |> GameEngine.resolve("accdd")
        |> GameEngine.letter_map()

      assert map == %{correct: ["A", "C"], incorrect: [], invalid: ["D"]}
    end
  end

  describe "gameplay" do
    test "correct guess wins the game" do
      game = "sugar" |> GameEngine.new() |> GameEngine.resolve("sugar")
      assert game.over?
      assert GameEngine.won?(game)
      assert GameEngine.guesses_left(game) == 5
    end

    test "bad guess looses the game after exhausting guesses" do
      game = GameEngine.new("sugar")
      game = Enum.reduce(1..6, game, fn _i, game -> GameEngine.resolve(game, "hoist") end)
      assert game.over?
      assert not GameEngine.won?(game)
      assert GameEngine.guesses_left(game) == 0
    end
  end
end
