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
end
